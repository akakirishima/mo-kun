import { Content, LiveServerMessage } from "@google/genai";
import { randomUUID } from "node:crypto";
import WebSocket from "ws";
import { buildAppDateKey } from "../services/app-date.js";
import { AiService } from "../services/ai-service.js";
import { buildAssistantSystemInstruction } from "../services/ai-service.js";
import { DailyBubbleService } from "../services/daily-bubble-service.js";
import { AppConfig, loadConfig } from "../config.js";
import { AppRepository } from "../repositories/app-repository.js";
import {
  ClientControlMessage,
  ParsedClientMessage,
  ServerControlMessage,
  serializeServerMessage,
} from "./live-protocol.js";
import { GeminiLiveSession } from "./gemini-live-session.js";
import { TranscriptAssembler, TranscriptEvent } from "./transcript-assembler.js";

type StartSessionContext = {
  threadId: string;
  voiceSessionId: string;
};

export class LiveSessionManager {
  private readonly transcriptAssembler = new TranscriptAssembler();
  private readonly geminiSession: GeminiLiveSession;
  private readonly acceptanceNotes = [
    "send_client_content is used for seed context only",
    "one live event may include multiple parts and all parts are processed",
    "Vertex deployment uses Gemini 2.5 Live models by default",
    "function calling in the live path is disabled in MVP",
    "proactive audio and affective dialog are disabled in MVP",
    "thinking config is omitted because Vertex Gemini Live 2.5 native audio does not support thinking",
  ];
  private activeContext: StartSessionContext | null = null;
  private currentModel: string | null = null;
  private fallbackUsed = false;
  private lastPersistedTurnId: string | null = null;
  private turnAwaitingAdvance = false;
  private pendingCompletedTurnId: string | null = null;
  private closed = false;

  constructor(
    private readonly socket: WebSocket,
    private readonly userId: string,
    private readonly repository: AppRepository,
    private readonly dailyBubbleService: DailyBubbleService,
    private readonly aiService: AiService,
    private readonly config: AppConfig = loadConfig(),
  ) {
    this.geminiSession = new GeminiLiveSession(config);
  }

  async handleMessage(parsed: ParsedClientMessage) {
    if (parsed.kind === "audio") {
      this.handleAudioChunk(parsed.audioBytes);
      return;
    }
    await this.handleControl(parsed.message);
  }

  async close(params?: { code?: number; reason?: string }) {
    if (this.closed) {
      return;
    }
    this.closed = true;
    await this.persistCurrentTurnSnapshot({
      preferResolvedTexts: true,
    });
    this.geminiSession.close();
    this.send({
      type: "session.closed",
      code: params?.code,
      reason: params?.reason,
    });
    this.socket.close();
  }

  private async handleControl(message: ClientControlMessage) {
    switch (message.type) {
      case "session.start":
        await this.startSession(message);
        return;
      case "session.stop":
        await this.close({ reason: "client_stop" });
        return;
      case "audio.flush":
        this.geminiSession.flushAudioStream();
        return;
      case "client.ping":
        this.send({
          type: "client.pong",
          ts: message.ts ?? null,
        });
        return;
    }
  }

  private handleAudioChunk(audioBytes: Buffer) {
    if (this.activeContext == null) {
      this.sendError("session_not_ready", "Live session is not started yet.");
      return;
    }
    this.geminiSession.sendAudioChunk(audioBytes);
  }

  private async startSession(message: Extract<ClientControlMessage, { type: "session.start" }>) {
    if (this.activeContext != null) {
      this.sendError("session_already_started", "Session is already active.");
      return;
    }
    if (!message.threadId) {
      this.sendError("invalid_thread_id", "threadId is required.");
      return;
    }

    const threadOwner = await this.repository.getThreadOwner(message.threadId);
    if (threadOwner !== this.userId) {
      this.sendError("forbidden_thread_access", "Thread access is forbidden.");
      return;
    }

    const character = await this.repository.getCharacterContext(this.userId);
    if (!character) {
      this.sendError("character_not_found", "Character context is missing.");
      return;
    }

    const storedResume = await this.repository.getLiveSessionHandle({
      threadId: message.threadId,
      sessionId: message.resumeSessionId,
    });
    const resumeHandle = message.resumeHandle?.trim() || storedResume?.handle || null;
    const recentMessages = await this.repository.getRecentMessages(message.threadId, 12);
    const userVoiceName = await this.repository.getUserVoiceName(this.userId);
    const personaInstruction = buildAssistantSystemInstruction(
      String(character.name ?? "Self"),
      typeof character.personaPrompt === "string" ? character.personaPrompt : undefined,
    );
    const historySeed = buildHistorySeed(recentMessages);

    console.info("Live session connecting", {
      userId: this.userId,
      threadId: message.threadId,
      hasResumeHandle: resumeHandle != null,
      voiceName: userVoiceName ?? this.config.ttsVoiceName,
    });

    const liveConnection = await this.geminiSession.connect({
      personaInstruction,
      historySeed,
      resumeHandle,
      voiceName: userVoiceName,
      onMessage: (serverMessage) => {
        void this.handleServerMessage(serverMessage);
      },
      onClose: (event) => {
        console.warn("Gemini Live session closed", {
          userId: this.userId,
          threadId: message.threadId,
          code: event.code,
          reason: event.reason,
        });
        if (!this.closed) {
          this.send({
            type: "session.closed",
            code: event.code,
            reason: event.reason,
          });
        }
      },
      onError: (error) => {
        console.error("Gemini Live session error", {
          userId: this.userId,
          threadId: message.threadId,
          detail: error instanceof Error ? error.message : "unknown_error",
        });
        this.sendError(
          "gemini_live_error",
          error instanceof Error ? error.message : "unknown_error",
          true,
        );
      },
    });

    this.activeContext = {
      threadId: message.threadId,
      voiceSessionId: randomUUID(),
    };
    this.currentModel = liveConnection.model;
    this.fallbackUsed = liveConnection.fallbackUsed;

    console.info("Live session ready", {
      userId: this.userId,
      threadId: message.threadId,
      model: liveConnection.model,
      fallbackUsed: liveConnection.fallbackUsed,
      resumed: resumeHandle != null,
      voiceName: userVoiceName ?? this.config.ttsVoiceName,
    });

    this.send({
      type: "session.ready",
      sessionId: this.activeContext.voiceSessionId,
      threadId: message.threadId,
      model: liveConnection.model,
      resumed: resumeHandle != null,
      fallbackUsed: liveConnection.fallbackUsed,
      acceptance: this.acceptanceNotes,
    });
  }

  private async handleServerMessage(message: LiveServerMessage) {
    if (this.activeContext == null) {
      return;
    }

    if (message.setupComplete?.sessionId) {
      this.activeContext = {
        ...this.activeContext,
        voiceSessionId: message.setupComplete.sessionId,
      };
    }

    if (message.sessionResumptionUpdate?.newHandle && this.activeContext != null) {
      await this.repository.saveLiveSessionHandle({
        threadId: this.activeContext.threadId,
        userId: this.userId,
        sessionId: this.activeContext.voiceSessionId,
        handle: message.sessionResumptionUpdate.newHandle,
        resumable: message.sessionResumptionUpdate.resumable === true,
        ttlSeconds: this.config.liveSessionHandleTtlSeconds,
        lastConsumedClientMessageIndex:
          message.sessionResumptionUpdate.lastConsumedClientMessageIndex ?? null,
      });
      this.send({
        type: "session.resumption",
        sessionId: this.activeContext.voiceSessionId,
        handle: message.sessionResumptionUpdate.newHandle,
        resumable: message.sessionResumptionUpdate.resumable === true,
        lastConsumedClientMessageIndex:
          message.sessionResumptionUpdate.lastConsumedClientMessageIndex ?? null,
      });
    }

    if (message.goAway) {
      this.send({
        type: "session.goaway",
        timeLeft: message.goAway.timeLeft,
      });
    }

    const serverContent = message.serverContent;
    if (!serverContent) {
      return;
    }

    const inputTranscription = serverContent.inputTranscription;
    const outputTranscription = serverContent.outputTranscription;

    if (serverContent.interrupted) {
      this.forwardTranscriptEvents(
        this.transcriptAssembler.nextOutput(outputTranscription),
      );
      const interruptedTurn = this.transcriptAssembler.currentResolvedTexts();
      await this.persistTurnSnapshot(interruptedTurn);
      this.turnAwaitingAdvance = true;
      this.send({
        type: "assistant.interrupted",
        turnId: interruptedTurn.turnId,
      });
      this.beginNextTurnIfNeeded(inputTranscription);
      this.forwardTranscriptEvents(
        this.transcriptAssembler.nextInput(inputTranscription),
      );
    } else {
      this.forwardTranscriptEvents(
        this.transcriptAssembler.nextInput(inputTranscription),
      );
      this.forwardTranscriptEvents(
        this.transcriptAssembler.nextOutput(outputTranscription),
      );
    }

    for (const part of extractParts(serverContent.modelTurn)) {
      const inlineData = part.inlineData;
      if (!inlineData?.data || !inlineData.mimeType?.startsWith("audio/")) {
        continue;
      }
      this.socket.send(Buffer.from(inlineData.data, "base64"), { binary: true });
    }

    if (serverContent.waitingForInput) {
      const waitingTurn = this.transcriptAssembler.currentResolvedTexts();
      this.send({
        type: "session.waiting_for_input",
        turnId: waitingTurn.turnId,
      });
      await this.persistTurnSnapshot(waitingTurn);
      this.turnAwaitingAdvance = true;
    }

    if (serverContent.turnComplete) {
      const completedTurnId =
        this.pendingCompletedTurnId ??
        this.transcriptAssembler.currentResolvedTexts().turnId;
      this.send({
        type: "assistant.turn_complete",
        turnId: completedTurnId,
      });
      if (this.pendingCompletedTurnId != null) {
        this.pendingCompletedTurnId = null;
        return;
      }
      await this.persistCurrentTurnSnapshot();
      this.transcriptAssembler.beginNextTurn();
      this.turnAwaitingAdvance = false;
    }
  }

  private beginNextTurnIfNeeded(transcription?: { text?: string | null }) {
    const hasInputText = typeof transcription?.text === "string" && transcription.text.trim().length > 0;
    if (!hasInputText || !this.turnAwaitingAdvance) {
      return;
    }

    this.pendingCompletedTurnId = this.transcriptAssembler.currentResolvedTexts().turnId;
    this.transcriptAssembler.beginNextTurn();
    this.turnAwaitingAdvance = false;
  }

  private async persistCurrentTurnSnapshot(params?: { preferResolvedTexts?: boolean }) {
    const snapshot = params?.preferResolvedTexts
      ? this.transcriptAssembler.currentResolvedTexts()
      : this.bestEffortCurrentTurnTexts();
    await this.persistTurnSnapshot(snapshot);
  }

  private bestEffortCurrentTurnTexts() {
    const finalized = this.transcriptAssembler.currentFinalTexts();
    if (finalized.inputText && finalized.outputText) {
      return finalized;
    }
    return this.transcriptAssembler.currentResolvedTexts();
  }

  private async persistTurnSnapshot(snapshot: {
    turnId: string;
    inputText: string;
    outputText: string;
  }) {
    await this.persistCompletedTurn(snapshot.turnId, snapshot.inputText, snapshot.outputText);
  }

  private async persistCompletedTurn(turnId: string, inputText: string, outputText: string) {
    if (this.activeContext == null || this.lastPersistedTurnId == turnId) {
      return;
    }
    const userText = inputText.trim();
    const assistantText = outputText.trim();
    if (!userText || !assistantText) {
      return;
    }

    this.lastPersistedTurnId = turnId;
    await this.repository.appendConversation({
      threadId: this.activeContext.threadId,
      userId: this.userId,
      userText,
      assistantText,
      clientMessageId: `live-${Date.now()}`,
      userInputType: "voice",
      transport: "live",
      voiceSessionId: this.activeContext.voiceSessionId,
      turnId,
    });

    const dateKey = buildAppDateKey(new Date());
    const dayMessages = await this.repository.getMessagesForDateKey(
      this.activeContext.threadId,
      dateKey,
    );
    const summary = await this.aiService.generateDailySummary({
      dateKey,
      messages: dayMessages,
    });
    await this.repository.saveDailySummary(this.userId, summary);
    await this.dailyBubbleService.refreshTodayBubbleFromSummary({
      userId: this.userId,
      summary,
    });
  }

  private forwardTranscriptEvents(events: TranscriptEvent[]) {
    for (const event of events) {
      switch (event.kind) {
        case "input_partial":
          this.send({
            type: "transcript.input.partial",
            turnId: event.turnId,
            text: event.text,
          });
          break;
        case "input_final":
          this.send({
            type: "transcript.input.final",
            turnId: event.turnId,
            text: event.text,
          });
          break;
        case "output_partial":
          this.send({
            type: "transcript.output.partial",
            turnId: event.turnId,
            text: event.text,
          });
          break;
        case "output_final":
          this.send({
            type: "transcript.output.final",
            turnId: event.turnId,
            text: event.text,
          });
          break;
      }
    }
  }

  private send(message: ServerControlMessage) {
    if (this.socket.readyState !== WebSocket.OPEN) {
      return;
    }
    this.socket.send(serializeServerMessage(message));
  }

  private sendError(code: string, detail?: string, retryable = false) {
    this.send({
      type: "error",
      code,
      detail,
      retryable,
    });
  }
}

function buildHistorySeed(messages: Array<{ role?: string; text?: string }>): string | undefined {
  const lines = messages
    .map((message) => {
      const text = String(message.text ?? "").trim();
      if (!text) {
        return null;
      }
      const label = message.role === "assistant" ? "パートナー" : "ユーザー";
      return `${label}: ${text}`;
    })
    .filter((value): value is string => value != null);

  if (lines.length === 0) {
    return undefined;
  }
  return [
    "以下は直近の会話履歴です。以降のリアルタイム会話でもこの流れを保ってください。",
    ...lines,
  ].join("\n");
}

function extractParts(modelTurn?: Content): Array<{ inlineData?: { data?: string; mimeType?: string } }> {
  if (!modelTurn?.parts || !Array.isArray(modelTurn.parts)) {
    return [];
  }
  return modelTurn.parts as Array<{ inlineData?: { data?: string; mimeType?: string } }>;
}

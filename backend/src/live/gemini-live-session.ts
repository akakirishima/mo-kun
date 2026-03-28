import {
  EndSensitivity,
  GoogleGenAI,
  LiveServerMessage,
  Modality,
  Session,
  StartSensitivity,
} from "@google/genai";
import { AppConfig, loadConfig } from "../config.js";
import { LIVE_PCM_INPUT_MIME } from "./live-protocol.js";

export type GeminiLiveConnection = {
  model: string;
  session: Session;
  fallbackUsed: boolean;
};

export class GeminiLiveSessionError extends Error {
  constructor(message: string, cause?: unknown) {
    super(message, { cause });
    this.name = "GeminiLiveSessionError";
  }
}

export class GeminiLiveSession {
  private readonly client: GoogleGenAI;
  private activeSession: Session | null = null;

  constructor(private readonly config: AppConfig = loadConfig()) {
    this.client = new GoogleGenAI({
      vertexai: true,
      project: config.projectId,
      location: config.liveVertexLocation,
    });
  }

  async connect(params: {
    personaInstruction: string;
    historySeed?: string;
    resumeHandle?: string | null;
    voiceName?: string | null;
    onMessage: (message: LiveServerMessage) => void;
    onClose: (event: { code?: number; reason?: string }) => void;
    onError: (error: unknown) => void;
  }): Promise<GeminiLiveConnection> {
    const candidates = [...new Set([
      this.config.livePrimaryModel,
      this.config.liveFallbackModel,
    ])];
    let lastError: unknown;

    for (let index = 0; index < candidates.length; index += 1) {
      const model = candidates[index]!;
      try {
        const speechConfig = buildLiveSpeechConfig({
          model,
          defaultLanguageCode: this.config.ttsLanguageCode,
          voiceName: params.voiceName ?? this.config.ttsVoiceName,
        });
        const session = await this.client.live.connect({
          model,
          config: {
            responseModalities: [Modality.AUDIO],
            systemInstruction: params.personaInstruction,
            speechConfig,
            inputAudioTranscription: {
              languageCodes: ["ja-JP"],
            },
            outputAudioTranscription: {
              languageCodes: ["ja-JP"],
            },
            sessionResumption: {
              handle: params.resumeHandle ?? undefined,
              transparent: true,
            },
            realtimeInputConfig: {
              automaticActivityDetection: {
                disabled: false,
                startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
                endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
                prefixPaddingMs: 20,
                silenceDurationMs: 100,
              },
            },
            contextWindowCompression: {
              slidingWindow: {},
            },
          },
          callbacks: {
            onmessage: params.onMessage,
            onclose: (event) => {
              params.onClose({
                code: event.code,
                reason: event.reason,
              });
            },
            onerror: (event) => {
              params.onError(event.error);
            },
          },
        });

        this.activeSession = session;
        if (params.historySeed && !params.resumeHandle) {
          session.sendClientContent({
            turns: params.historySeed,
            turnComplete: false,
          });
        }

        return {
          model,
          session,
          fallbackUsed: index > 0,
        };
      } catch (error) {
        lastError = error;
      }
    }

    throw new GeminiLiveSessionError("live_connect_failed", lastError);
  }

  sendAudioChunk(audioBytes: Buffer) {
    this.activeSession?.sendRealtimeInput({
      audio: {
        data: audioBytes.toString("base64"),
        mimeType: LIVE_PCM_INPUT_MIME,
      },
    });
  }

  flushAudioStream() {
    this.activeSession?.sendRealtimeInput({
      audioStreamEnd: true,
    });
  }

  close() {
    this.activeSession?.close();
    this.activeSession = null;
  }
}

function buildLiveSpeechConfig(params: {
  model: string;
  defaultLanguageCode: string;
  voiceName: string;
}) {
  const isNativeAudioModel = params.model.includes("native-audio");
  return {
    ...(!isNativeAudioModel
        ? { languageCode: params.defaultLanguageCode }
        : {}),
    voiceConfig: {
      prebuiltVoiceConfig: {
        voiceName: params.voiceName,
      },
    },
  };
}

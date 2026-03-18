import cors from "cors";
import express from "express";
import multer from "multer";
import { loadConfig } from "./config.js";
import { getDb, getStorageClient } from "./lib/firebase.js";
import { requireAuth, type AuthedRequest } from "./middleware/auth.js";
import { AppRepository } from "./repositories/app-repository.js";
import { AiService, AiServiceError } from "./services/ai-service.js";
import {
  CharacterImageService,
  CloudStorageImageStore,
} from "./services/character-image-service.js";
import { buildAppDateKey } from "./services/app-date.js";
import { DailyBubbleService } from "./services/daily-bubble-service.js";
import { SpeechService, SpeechServiceError } from "./services/speech-service.js";

const config = loadConfig();
const app = express();
const repository = new AppRepository(getDb());
const aiService = new AiService(config);
const speechService = new SpeechService(config);
const dailyBubbleService = new DailyBubbleService(repository, aiService);
const imageService = new CharacterImageService(
  repository,
  aiService,
  new CloudStorageImageStore(getStorageClient().bucket(config.imageBucket)),
);
const voiceUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

app.use(express.json());
app.use(cors());

app.get("/health", (_request, response) => {
  response.json({ ok: true });
});

app.post("/v1/session/initialize", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const session = await repository.initializeSession(authedRequest.user.uid);
    if (!session.needsOnboarding) {
      await dailyBubbleService.ensureTodayBubble({
        userId: authedRequest.user.uid,
      });
    }
    response.json(session);
  } catch (error) {
    response.status(500).json({
      error: "session_initialize_failed",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
});

app.post("/v1/characters", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const profile = {
      displayName: String(request.body.displayName ?? "").trim(),
      goal: String(request.body.goal ?? "").trim(),
      partnerStyle: String(request.body.partnerStyle ?? "").trim(),
      weakPoints: Array.isArray(request.body.weakPoints)
        ? request.body.weakPoints.map(String)
        : [],
    };

    if (!profile.displayName || !profile.goal || !profile.partnerStyle) {
      response.status(400).json({ error: "invalid_character_payload" });
      return;
    }

    const character = aiService.generateCharacterDraft(profile);
    const created = await repository.createCharacter({
      userId: authedRequest.user.uid,
      profile,
      character,
    });
    await imageService.generateAndPersist({
      userId: authedRequest.user.uid,
      title: "最初の姿",
      optionalNote: profile.goal,
    });
    await dailyBubbleService.ensureTodayBubble({
      userId: authedRequest.user.uid,
    });

    response.json({
      characterId: created.characterId,
      threadId: created.threadId,
    });
  } catch (error) {
    response.status(500).json({
      error: "create_character_failed",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
});

app.post("/v1/chat/messages", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const threadId = String(request.body.threadId ?? "").trim();
    const text = String(request.body.text ?? "").trim();
    const clientMessageId = String(request.body.clientMessageId ?? "").trim();

    if (!threadId || !text || !clientMessageId) {
      response.status(400).json({ error: "invalid_chat_payload" });
      return;
    }

    const threadOwner = await repository.getThreadOwner(threadId);
    if (!threadOwner) {
      response.status(404).json({ error: "thread_not_found" });
      return;
    }

    if (threadOwner !== authedRequest.user.uid) {
      response.status(403).json({ error: "forbidden_thread_access" });
      return;
    }

    const character = await repository.getCharacterContext(authedRequest.user.uid);
    if (!character) {
      response.status(404).json({ error: "character_not_found" });
      return;
    }

    const recentMessages = await repository.getRecentMessages(threadId);
    const assistantText = await aiService.generateAssistantReply({
      characterName: String(character.name ?? "Self"),
      personaPrompt:
        typeof character.personaPrompt === "string" ? character.personaPrompt : undefined,
      recentMessages,
      userText: text,
    });
    const saved = await repository.appendConversation({
      threadId,
      userId: authedRequest.user.uid,
      userText: text,
      clientMessageId,
      assistantText,
    });
    const dateKey = buildAppDateKey(new Date());
    const dayMessages = await repository.getMessagesForDateKey(threadId, dateKey);
    const summary = await aiService.generateDailySummary({
      dateKey,
      messages: dayMessages,
    });
    await repository.saveDailySummary(authedRequest.user.uid, summary);

    response.json({
      threadId,
      ...saved,
    });
  } catch (error) {
    if (error instanceof AiServiceError) {
      response.status(503).json({
        error: "assistant_generation_failed",
        detail: error.message,
      });
      return;
    }

    response.status(500).json({
      error: "send_message_failed",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
});

app.post(
  "/v1/chat/voice",
  requireAuth,
  voiceUpload.single("audio"),
  async (request, response) => {
    try {
      const authedRequest = request as AuthedRequest;
      const threadId = String(request.body.threadId ?? "").trim();
      const clientMessageId = String(request.body.clientMessageId ?? "").trim();
      const durationMs = Number(request.body.durationMs ?? 0);
      const audioFile = request.file;

      if (!threadId || !clientMessageId || !audioFile?.buffer?.length) {
        response.status(400).json({ error: "invalid_voice_payload" });
        return;
      }

      if (durationMs > 20_000) {
        response.status(400).json({ error: "voice_too_long" });
        return;
      }

      const threadOwner = await repository.getThreadOwner(threadId);
      if (!threadOwner) {
        response.status(404).json({ error: "thread_not_found" });
        return;
      }

      if (threadOwner !== authedRequest.user.uid) {
        response.status(403).json({ error: "forbidden_thread_access" });
        return;
      }

      const character = await repository.getCharacterContext(authedRequest.user.uid);
      if (!character) {
        response.status(404).json({ error: "character_not_found" });
        return;
      }

      const transcriptText = await speechService.transcribeShortWav({
        audioBytes: audioFile.buffer,
      });
      const recentMessages = await repository.getRecentMessages(threadId);
      const assistantText = await aiService.generateAssistantReply({
        characterName: String(character.name ?? "Self"),
        personaPrompt:
          typeof character.personaPrompt === "string" ? character.personaPrompt : undefined,
        recentMessages,
        userText: transcriptText,
      });
      const saved = await repository.appendConversation({
        threadId,
        userId: authedRequest.user.uid,
        userText: transcriptText,
        clientMessageId,
        assistantText,
        userInputType: "voice",
      });
      const dateKey = buildAppDateKey(new Date());
      const dayMessages = await repository.getMessagesForDateKey(threadId, dateKey);
      const summary = await aiService.generateDailySummary({
        dateKey,
        messages: dayMessages,
      });
      await repository.saveDailySummary(authedRequest.user.uid, summary);

      try {
        const synthesized = await speechService.synthesizeAssistantSpeech({
          text: assistantText,
        });
        response.json({
          threadId,
          transcriptText,
          assistantText,
          assistantAudioBase64: synthesized.audioBytes.toString("base64"),
          assistantAudioMimeType: synthesized.mimeType,
          audioStatus: "ready",
          ...saved,
        });
      } catch (error) {
        console.error("Assistant TTS failed", error);
        response.json({
          threadId,
          transcriptText,
          assistantText,
          assistantAudioBase64: null,
          assistantAudioMimeType: null,
          audioStatus: "failed",
          ...saved,
        });
      }
    } catch (error) {
      if (error instanceof SpeechServiceError) {
        response.status(422).json({
          error: "speech_processing_failed",
          detail: error.message,
        });
        return;
      }
      if (error instanceof AiServiceError) {
        response.status(503).json({
          error: "assistant_generation_failed",
          detail: error.message,
        });
        return;
      }

      response.status(500).json({
        error: "voice_message_failed",
        detail: error instanceof Error ? error.message : "unknown_error",
      });
    }
  },
);

app.post("/v1/characters/image", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const title = String(request.body.title ?? "更新した姿");
    const reportText = String(request.body.reportText ?? "").trim();
    const image = await imageService.generateAndPersist({
      userId: authedRequest.user.uid,
      title,
      optionalNote: reportText,
    });
    response.json(image);
  } catch (error) {
    if (error instanceof AiServiceError) {
      response.status(503).json({
        error: "generate_image_failed",
        detail: error.message,
      });
      return;
    }
    if (error instanceof Error && error.message === "character_not_found") {
      response.status(404).json({ error: "character_not_found" });
      return;
    }
    response.status(500).json({
      error: "generate_image_failed",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
});

app.post("/v1/jobs/daily-refresh", async (request, response) => {
  if (request.header("x-daily-refresh-secret") !== config.dailyRefreshSecret) {
    response.status(401).json({ error: "invalid_job_secret" });
    return;
  }

  try {
    const targetDate = buildAppDateKey(new Date());
    const users = await repository.listUsersForRefresh();
    for (const userId of users) {
      const threadId = `${userId}_main`;
      const messages = await repository.getMessagesForDateKey(threadId, targetDate);
      const summary = await aiService.generateDailySummary({
        dateKey: targetDate,
        messages,
      });
      await repository.saveDailySummary(userId, summary);
      await dailyBubbleService.ensureTodayBubble({ userId });
      await imageService.generateAndPersist({
        userId,
        title: "昨日の報告を反映した姿",
        todaySummary: summary,
      });
    }

    response.json({ ok: true, dateKey: targetDate, refreshedUsers: users.length });
  } catch (error) {
    response.status(500).json({
      error: "daily_refresh_failed",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
});

app.listen(config.port, () => {
  console.log(`mo-kun backend listening on ${config.port}`);
});

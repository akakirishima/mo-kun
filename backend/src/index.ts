import cors from "cors";
import express from "express";
import { loadConfig } from "./config.js";
import { getDb } from "./lib/firebase.js";
import { requireAuth, type AuthedRequest } from "./middleware/auth.js";
import { AppRepository } from "./repositories/app-repository.js";
import { AiService, AiServiceError } from "./services/ai-service.js";

const config = loadConfig();
const app = express();
const repository = new AppRepository(getDb());
const aiService = new AiService(config);

app.use(express.json());
app.use(cors());

app.get("/health", (_request, response) => {
  response.json({ ok: true });
});

app.post("/v1/session/initialize", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const session = await repository.initializeSession(authedRequest.user.uid);
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
    const initialImage = aiService.generateImageDraft({
      title: "最初の姿",
      visualPromptBase: character.visualPromptBase,
      reportText: profile.goal,
      userId: authedRequest.user.uid,
    });
    await repository.saveCharacterImage({
      userId: authedRequest.user.uid,
      image: initialImage,
      status: "ready",
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
      characterName: String(character.name ?? "Mori"),
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

app.post("/v1/characters/image", requireAuth, async (request, response) => {
  try {
    const authedRequest = request as AuthedRequest;
    const title = String(request.body.title ?? "更新した姿");
    const reportText = String(request.body.reportText ?? "").trim();
    const character = await repository.getCharacterContext(authedRequest.user.uid);
    if (!character) {
      response.status(404).json({ error: "character_not_found" });
      return;
    }

    const image = aiService.generateImageDraft({
      title,
      visualPromptBase: String(character.visualPromptBase ?? ""),
      reportText,
      userId: authedRequest.user.uid,
    });
    await repository.saveCharacterImage({
      userId: authedRequest.user.uid,
      image,
      status: "ready",
    });
    response.json(image);
  } catch (error) {
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
    const targetDate = buildTargetDateKey(new Date());
    const users = await repository.listUsersForRefresh();
    for (const userId of users) {
      const threadId = `${userId}_main`;
      const messages = await repository.getRecentMessages(threadId, 40);
      const summary = aiService.generateDailySummary({
        dateKey: targetDate,
        messages,
      });
      await repository.saveDailySummary(userId, summary);

      const character = await repository.getCharacterContext(userId);
      if (!character) {
        continue;
      }
      const image = aiService.generateImageDraft({
        title: "昨日の報告を反映した姿",
        visualPromptBase: String(character.visualPromptBase ?? ""),
        reportText: summary.doneThings.join(" / "),
        userId,
      });
      await repository.saveCharacterImage({
        userId,
        image,
        status: "ready",
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

function buildTargetDateKey(now: Date): string {
  const shifted = new Date(now);
  shifted.setMinutes(shifted.getMinutes() - 185);
  const year = shifted.getFullYear();
  const month = `${shifted.getMonth() + 1}`.padStart(2, "0");
  const day = `${shifted.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

import { Router } from "express";
import { AuthedRequest, requireAuth } from "../middleware/auth.js";
import { AppRepository } from "../repositories/app-repository.js";
import { CharacterService } from "../services/character-service.js";
import { ChatService } from "../services/chat-service.js";
import { DailyRefreshService } from "../services/daily-refresh-service.js";
import { ImageService } from "../services/image-service.js";

export function buildV1Router(params: {
  repository: AppRepository;
  characterService: CharacterService;
  chatService: ChatService;
  imageService: ImageService;
  dailyRefreshService: DailyRefreshService;
  dailyRefreshSecret: string;
}) {
  const router = Router();

  router.post("/session/initialize", requireAuth, async (request, response) => {
    const authedRequest = request as AuthedRequest;
    const session = await params.repository.initializeSession(authedRequest.user.uid);
    response.json(session);
  });

  router.post("/characters", requireAuth, async (request, response) => {
    const authedRequest = request as AuthedRequest;
    const body = request.body as {
      displayName?: string;
      goal?: string;
      partnerStyle?: string;
      weakPoints?: string[];
    };
    const draft = await params.characterService.createDraft({
      displayName: body.displayName ?? "",
      goal: body.goal ?? "",
      partnerStyle: body.partnerStyle ?? "",
      weakPoints: body.weakPoints ?? [],
    });
    const created = await params.repository.createCharacter({
      userId: authedRequest.user.uid,
      profile: {
        displayName: body.displayName ?? "",
        goal: body.goal ?? "",
        partnerStyle: body.partnerStyle ?? "",
        weakPoints: body.weakPoints ?? [],
      },
      character: draft,
    });
    response.status(201).json({
      ...created,
      character: draft,
    });
  });

  router.post("/chat/messages", requireAuth, async (request, response) => {
    const authedRequest = request as AuthedRequest;
    const body = request.body as {
      threadId?: string;
      text?: string;
      clientMessageId?: string;
    };
    if (!body.threadId || !body.text || !body.clientMessageId) {
      response.status(400).json({ error: "threadId, text, clientMessageId are required." });
      return;
    }

    const character = await params.repository.getCharacterContext(authedRequest.user.uid);
    const recentMessages = await params.repository.getRecentMessages(body.threadId, 20);
    const assistantText = await params.chatService.reply({
      userText: body.text,
      personaPrompt: String(character?.personaPrompt ?? ""),
      recentMessages,
    });
    const ids = await params.repository.appendConversation({
      threadId: body.threadId,
      userId: authedRequest.user.uid,
      userText: body.text,
      clientMessageId: body.clientMessageId,
      assistantText,
    });
    response.status(201).json({
      threadId: body.threadId,
      ...ids,
      reply: assistantText,
    });
  });

  router.post("/characters/image", requireAuth, async (request, response) => {
    const authedRequest = request as AuthedRequest;
    const body = request.body as { reportText?: string };
    const character = await params.repository.getCharacterContext(authedRequest.user.uid);
    if (!character) {
      response.status(404).json({ error: "Character not found." });
      return;
    }

    const image = await params.imageService.generate({
      userId: authedRequest.user.uid,
      characterName: String(character.name ?? "Mori"),
      visualPromptBase: String(character.visualPromptBase ?? ""),
      reportText: body.reportText ?? "初回プロフィール入力",
    });
    await params.repository.saveCharacterImage({
      userId: authedRequest.user.uid,
      image,
    });
    response.status(201).json(image);
  });

  router.post("/jobs/daily-refresh", async (request, response) => {
    const secret = request.header("x-daily-refresh-secret");
    if (secret != params.dailyRefreshSecret) {
      response.status(401).json({ error: "Invalid refresh secret." });
      return;
    }
    const result = await params.dailyRefreshService.refreshAllUsers();
    response.json(result);
  });

  return router;
}

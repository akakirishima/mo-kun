import { GoogleGenAI } from "@google/genai";
import { loadConfig, type AppConfig } from "../config.js";
import { CharacterDraft, DailySummaryDraft, ImageDraft } from "../types.js";

type CharacterProfileInput = {
  displayName: string;
  goal: string;
  partnerStyle: string;
  weakPoints: string[];
};

type MessageContext = Array<{ role?: string; text?: string }>;

export class AiServiceError extends Error {
  constructor(message: string, cause?: unknown) {
    super(message, { cause });
    this.name = "AiServiceError";
  }
}

export class AiService {
  private readonly client: GoogleGenAI;

  constructor(private readonly config: AppConfig = loadConfig()) {
    this.client = new GoogleGenAI({
      vertexai: true,
      project: config.projectId,
      location: config.vertexLocation,
    });
  }

  generateCharacterDraft(profile: CharacterProfileInput): CharacterDraft {
    const weakPoints =
      profile.weakPoints.length === 0
        ? "継続が途切れないように見守る"
        : `特に ${profile.weakPoints.join("、")} を気にかける`;

    return {
      name: `${profile.displayName || "Mori"}の相棒`,
      personaPrompt: [
        "あなたはユーザーの分身に近いAIパートナーです。",
        `ユーザーの目標: ${profile.goal}`,
        `接し方: ${profile.partnerStyle}`,
        `注意点: ${weakPoints}`,
      ].join("\n"),
      visualPromptBase: [
        "soft illustrated companion",
        `goal: ${profile.goal}`,
        `tone: ${profile.partnerStyle}`,
      ].join(", "),
      starterGreeting: `${profile.displayName || "きみ"}、今日から一緒に進もう。まずは今日のことを聞かせて。`,
    };
  }

  async generateAssistantReply(params: {
    characterName: string;
    personaPrompt?: string;
    recentMessages: MessageContext;
    userText: string;
  }): Promise<string> {
    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: buildAssistantPrompt(params.recentMessages, params.userText),
        config: {
          systemInstruction: buildAssistantSystemInstruction(
            params.characterName,
            params.personaPrompt,
          ),
          temperature: this.config.geminiTemperature,
          maxOutputTokens: this.config.geminiMaxOutputTokens,
        },
      });
      const normalized = normalizeAssistantReply(response.text);
      if (!normalized) {
        throw new AiServiceError("gemini_empty_response");
      }
      return normalized;
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini generateContent failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      if (error instanceof AiServiceError) {
        throw error;
      }
      throw new AiServiceError(`gemini_generate_content_failed: ${detail}`, error);
    }
  }

  generateImageDraft(params: {
    title: string;
    visualPromptBase: string;
    reportText: string;
    userId: string;
  }): ImageDraft {
    const slug = Date.now().toString();
    return {
      title: params.title,
      promptExcerpt: `${params.visualPromptBase} / ${params.reportText}`.trim(),
      imageUrl: `https://example.com/generated/${params.userId}/${slug}.png`,
    };
  }

  generateDailySummary(params: {
    dateKey: string;
    messages: MessageContext;
  }): DailySummaryDraft {
    const userMessages = params.messages
      .filter((message) => message.role === "user" && !!message.text)
      .map((message) => message.text!.trim())
      .filter((text) => text.length > 0);
    const doneThings = userMessages.slice(0, 3);
    const lead = doneThings.length === 0 ? "まだ報告がありません" : doneThings[0];

    return {
      dateKey: params.dateKey,
      title: "AIがまとめた今日の記録",
      mood: doneThings.length === 0 ? "静か" : "前向き",
      doneThings,
      reflection: `今日の流れは「${lead}」を中心に整理された。`,
      tomorrowNote: "明日は一言だけでも進捗を送って流れを続ける。",
    };
  }
}

export function buildAssistantSystemInstruction(
  characterName: string,
  personaPrompt?: string,
): string {
  return [
    `あなたは${characterName}という名前のAIパートナーです。`,
    "以下の人格設定に従って会話してください。",
    personaPrompt?.trim() || "ユーザーの近くで伴走する相棒として、短く自然に返答してください。",
    "返答ルール:",
    "- 日本語で答える",
    "- 短すぎず不自然にならない範囲で返す",
    "- 必要に応じて2〜5文程度で返してよい",
    "- ユーザーの今日の報告や気分を受け止める",
    "- ユーザーの努力や前進を自然にねぎらってよい",
    "- 会話が続けやすいように、一言だけやわらかく広げてもよい",
    "- ユーザーの発話をそのまま引用しすぎない",
    "- メタな説明やログ風の書き方をしない",
    "- 返答は必ず言い切りで終え、途中で切れたような文末にしない",
    "- 断定や説教を避け、会話として違和感のない表現にする",
    "- 明日の見た目や日記への反映を必要以上に強調しない",
  ].join("\n");
}

export function buildAssistantPrompt(
  recentMessages: MessageContext,
  userText: string,
): string {
  const historyLines = recentMessages
    .map((message) => {
      const text = normalizePromptText(message.text);
      if (!text) {
        return null;
      }

      if (message.role === "assistant") {
        return `パートナー: ${text}`;
      }

      if (message.role === "user") {
        return `ユーザー: ${text}`;
      }

      return null;
    })
    .filter((line): line is string => line != null);

  return [
    "以下は直近の会話履歴です。",
    historyLines.length > 0 ? historyLines.join("\n") : "履歴なし",
    "",
    `今回のユーザー入力: ${userText.trim()}`,
    "上の流れを踏まえて、会話として自然な返答を1つだけ作ってください。",
  ].join("\n");
}

export function normalizeAssistantReply(text?: string): string | null {
  if (!text) {
    return null;
  }

  const normalized = text.replace(/\r\n/g, "\n").trim();
  if (!normalized) {
    return null;
  }

  if (normalized.length <= 600) {
    return finalizeAssistantReply(normalized);
  }

  return finalizeAssistantReply(normalized.slice(0, 597).trimEnd());
}

function normalizePromptText(text?: string): string | null {
  const normalized = text?.trim();
  return normalized ? normalized : null;
}

function finalizeAssistantReply(text: string): string {
  const trimmed = text.trim();
  if (!trimmed) {
    return trimmed;
  }

  if (/[。！？!?」]$/.test(trimmed)) {
    return trimmed;
  }

  if (/[、,:：]$/.test(trimmed)) {
    const sentenceEndMatches = [...trimmed.matchAll(/[。！？!?]/g)];
    const lastSentenceEnd = sentenceEndMatches.at(-1);
    if (lastSentenceEnd && lastSentenceEnd.index != null) {
      return trimmed.slice(0, lastSentenceEnd.index + 1).trim();
    }
  }

  return `${trimmed}。`;
}

function extractErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    const cause = error.cause;
    if (cause instanceof Error && cause.message) {
      return `${error.message} | cause: ${cause.message}`;
    }
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  try {
    return JSON.stringify(error);
  } catch {
    return "unknown_error";
  }
}

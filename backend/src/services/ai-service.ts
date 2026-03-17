import { GoogleGenAI, Modality } from "@google/genai";
import { loadConfig, type AppConfig } from "../config.js";
import { CharacterDraft, DailySummaryDraft, StoredDailySummary } from "../types.js";

type CharacterProfileInput = {
  displayName: string;
  goal: string;
  partnerStyle: string;
  weakPoints: string[];
};

type MessageContext = Array<{ role?: string; text?: string }>;

type GeneratedImageAsset = {
  mimeType: string;
  imageBytes: Buffer;
};

type ImagePromptContext = {
  characterName: string;
  visualPromptBase: string;
  visualEvolutionMemo: string;
  todaySummary: string;
  optionalNote?: string;
};

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
        "keep the same core identity across daily updates",
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

  async generateVisualEvolutionMemo(params: {
    recentSummaries: StoredDailySummary[];
  }): Promise<string> {
    if (params.recentSummaries.length === 0) {
      return "まだ大きな変化は少なく、始まりの印象を保ちながら静かに成長している。";
    }

    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: buildVisualEvolutionPrompt(params.recentSummaries),
        config: {
          systemInstruction: buildVisualEvolutionSystemInstruction(),
          temperature: 0.35,
          maxOutputTokens: 180,
        },
      });
      const normalized = normalizeAssistantReply(response.text);
      if (!normalized) {
        throw new AiServiceError("visual_evolution_memo_empty");
      }
      return normalized;
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini visual memo generation failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      if (error instanceof AiServiceError) {
        throw error;
      }
      throw new AiServiceError(`visual_evolution_memo_failed: ${detail}`, error);
    }
  }

  buildCharacterImagePrompt(params: ImagePromptContext): string {
    return buildCharacterImagePrompt(params);
  }

  async generateCharacterImage(params: {
    prompt: string;
  }): Promise<GeneratedImageAsset> {
    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiImageModel,
        contents: params.prompt,
        config: {
          responseModalities: [Modality.TEXT, Modality.IMAGE],
        },
      });
      return extractGeneratedImage(response);
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini image generation failed", {
        model: this.config.geminiImageModel,
        location: this.config.vertexLocation,
        detail,
      });
      if (error instanceof AiServiceError) {
        throw error;
      }
      throw new AiServiceError(`gemini_image_generation_failed: ${detail}`, error);
    }
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

export function buildVisualEvolutionPrompt(recentSummaries: StoredDailySummary[]): string {
  const summaryLines = recentSummaries
    .map((summary, index) => {
      const doneThings = summary.doneThings.length > 0 ? summary.doneThings.join(" / ") : "報告なし";
      return [
        `#${index + 1} date: ${summary.dateKey}`,
        `title: ${summary.title}`,
        `mood: ${summary.mood}`,
        `done: ${doneThings}`,
        `reflection: ${summary.reflection}`,
        `tomorrow: ${summary.tomorrowNote}`,
      ].join("\n");
    })
    .join("\n\n");

  return [
    "直近7日分の振り返りから、相棒キャラクターの見た目ににじむ成長だけを短く要約してください。",
    "数値や実績を直接書かず、表情・姿勢・雰囲気・服装ディテールに落ちる変化だけをまとめてください。",
    "",
    summaryLines,
  ].join("\n");
}

export function buildVisualEvolutionSystemInstruction(): string {
  return [
    "あなたはキャラクターデザイン用の要約メモを作るアシスタントです。",
    "出力ルール:",
    "- 日本語で2〜4文に収める",
    "- 同一キャラクターの連続性を保つ方向で書く",
    "- 変化は自然で小さく積み上がるものだけを書く",
    "- 努力は表情、姿勢、服装ディテール、雰囲気に翻訳する",
    "- トロフィーや数値のような露骨な記号化は避ける",
    "- 箇条書きにしない",
  ].join("\n");
}

export function buildCharacterImagePrompt(params: ImagePromptContext): string {
  const optionalNote = params.optionalNote?.trim();

  return [
    `あなたは${params.characterName}という同一キャラクターの最新ビジュアルを生成する。`,
    "以下の情報をすべて守って、1枚の縦長イラストとして描写する。",
    "",
    "固定設定:",
    params.visualPromptBase.trim() || "soft illustrated companion",
    "",
    "直近7日間の成長メモ:",
    params.visualEvolutionMemo.trim(),
    "",
    "今日の振り返り:",
    params.todaySummary.trim(),
    "",
    "今回だけの補足:",
    optionalNote && optionalNote.length > 0 ? optionalNote : "補足なし",
    "",
    "連続性ルール:",
    "- 同一キャラクターとして継続性を保つ",
    "- 変化は1日ぶんとして自然で小さく積み上げる",
    "- 努力は表情、姿勢、服装ディテール、雰囲気で表現する",
    "- トロフィーや数値のような露骨な記号化は避ける",
    "- 画面内に文字を入れない",
    "- 暴力的、性的、過度に誇張された表現を避ける",
  ].join("\n");
}

export function summarizeDailySummary(summary: StoredDailySummary): string {
  const doneThings = summary.doneThings.length > 0 ? summary.doneThings.join(" / ") : "報告なし";
  return [
    `日付: ${summary.dateKey}`,
    `タイトル: ${summary.title}`,
    `気分: ${summary.mood}`,
    `やったこと: ${doneThings}`,
    `振り返り: ${summary.reflection}`,
    `明日メモ: ${summary.tomorrowNote}`,
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

export function extractGeneratedImage(response: unknown): GeneratedImageAsset {
  const parts = extractResponseParts(response);
  for (const part of parts) {
    const inlineData = part.inlineData;
    if (!inlineData?.data || !inlineData.mimeType?.startsWith("image/")) {
      continue;
    }
    return {
      mimeType: inlineData.mimeType,
      imageBytes: Buffer.from(inlineData.data, "base64"),
    };
  }

  throw new AiServiceError("gemini_image_response_missing_inline_data");
}

function extractResponseParts(
  response: unknown,
): Array<{ inlineData?: { data?: string; mimeType?: string } }> {
  if (typeof response !== "object" || response == null) {
    return [];
  }

  const candidateContainer = response as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ inlineData?: { data?: string; mimeType?: string } }>;
      };
    }>;
  };

  return candidateContainer.candidates?.flatMap((candidate) => candidate.content?.parts ?? []) ?? [];
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

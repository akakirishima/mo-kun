import {
  GoogleGenAI,
  Modality,
  createPartFromBase64,
  createPartFromText,
} from "@google/genai";
import { loadConfig, type AppConfig } from "../config.js";
import {
  CharacterDraft,
  DailyBubbleDraft,
  DailySummaryDraft,
  PhotoAnalysisDraft,
  StoredDailySummary,
} from "../types.js";

type CharacterProfileInput = {
  displayName: string;
  goal: string;
  partnerStyle: string;
  weakPoints: string[];
};

type MessageContext = Array<{ role?: string; text?: string; [key: string]: unknown }>;

type GeneratedImageAsset = {
  mimeType: string;
  imageBytes: Buffer;
};

type ImagePromptContext = {
  characterName: string;
  visualPromptBase: string;
  visualEvolutionMemo: string;
  todaySummary: string;
  sceneItems: string[];
  optionalNote?: string;
};

type DailySummaryCandidate = {
  title?: unknown;
  diaryBody?: unknown;
  mood?: unknown;
  doneThings?: unknown;
  reflection?: unknown;
  tomorrowNote?: unknown;
};

type RoomSceneItemsCandidate = {
  items?: unknown;
};

type DailyBubbleCandidate = {
  text?: unknown;
};

type PhotoAnalysisCandidate = {
  category?: unknown;
  summary?: unknown;
  activity?: unknown;
  food?: unknown;
  locationGuess?: unknown;
  confidence?: unknown;
  needsConfirmation?: unknown;
  confirmationPrompt?: unknown;
  reactionHint?: unknown;
};

const DAILY_SUMMARY_RESPONSE_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["title", "diaryBody", "mood", "doneThings", "reflection", "tomorrowNote"],
  properties: {
    title: { type: "string" },
    diaryBody: { type: "string" },
    mood: { type: "string" },
    doneThings: {
      type: "array",
      items: { type: "string" },
    },
    reflection: { type: "string" },
    tomorrowNote: { type: "string" },
  },
};

const ROOM_SCENE_ITEMS_RESPONSE_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["items"],
  properties: {
    items: {
      type: "array",
      items: { type: "string" },
    },
  },
};

const DAILY_BUBBLE_RESPONSE_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["text"],
  properties: {
    text: { type: "string" },
  },
};

const PHOTO_ANALYSIS_RESPONSE_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: [
    "category",
    "summary",
    "activity",
    "food",
    "locationGuess",
    "confidence",
    "needsConfirmation",
    "confirmationPrompt",
    "reactionHint",
  ],
  properties: {
    category: { type: "string" },
    summary: { type: "string" },
    activity: { type: "string" },
    food: { type: "string" },
    locationGuess: { type: "string" },
    confidence: { type: "string" },
    needsConfirmation: { type: "boolean" },
    confirmationPrompt: { type: "string" },
    reactionHint: { type: "string" },
  },
};

export const DEFAULT_ROOM_VISUAL_PROMPT_BASE = [
  "cute pastel pixel-art isometric room",
  "fixed cozy bedroom layout viewed from a slightly top-down angle",
  "pink walls, mint furniture, warm wooden floor, soft daylight",
  "bed on the left, desk and computer on the back wall, two windows, round rug, small table, sofa, cabinet, framed wall art",
  "the same room layout stays consistent across daily updates",
  "a cute companion character stays near the center of the room as the main focus",
  "wide horizontal composition showing the whole room",
].join(", ");

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
      name: profile.displayName || "Self",
      personaPrompt: [
        "あなたはユーザー自身を投影した内なる声です。",
        `ユーザーの目標: ${profile.goal}`,
        `話し方の方向性: ${profile.partnerStyle}`,
        `注意点: ${weakPoints}`,
        "立ち位置: 自分を整理し、次の一歩を静かに促す。",
      ].join("\n"),
      visualPromptBase: [
        DEFAULT_ROOM_VISUAL_PROMPT_BASE,
        profile.goal ? `goal mood hint: ${profile.goal}` : null,
        profile.partnerStyle ? `inner voice tone hint: ${profile.partnerStyle}` : null,
      ].filter((value): value is string => value != null && value.length > 0).join(", "),
      starterGreeting: "今日は何を残したい？",
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

  async generateRoomSceneItems(params: {
    todaySummary: string;
    messages: MessageContext;
    optionalNote?: string;
  }): Promise<string[]> {
    const fallback = buildFallbackRoomSceneItems(params);

    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: buildRoomSceneItemsPrompt(params),
        config: {
          systemInstruction: buildRoomSceneItemsSystemInstruction(),
          temperature: 0.2,
          maxOutputTokens: 180,
          responseMimeType: "application/json",
          responseJsonSchema: ROOM_SCENE_ITEMS_RESPONSE_JSON_SCHEMA,
        },
      });
      return normalizeGeneratedRoomSceneItems(response.text, fallback);
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini room scene item extraction failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      return fallback;
    }
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

  async generatePhotoAnalysis(params: {
    photoBytes: Buffer;
    mimeType: string;
    userText?: string;
  }): Promise<PhotoAnalysisDraft> {
    const fallback = buildFallbackPhotoAnalysis(params.userText);

    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: [
          createPartFromText(buildPhotoAnalysisPrompt(params.userText)),
          createPartFromBase64(params.photoBytes.toString("base64"), params.mimeType),
        ],
        config: {
          systemInstruction: buildPhotoAnalysisSystemInstruction(),
          temperature: 0.2,
          maxOutputTokens: 220,
          responseMimeType: "application/json",
          responseJsonSchema: PHOTO_ANALYSIS_RESPONSE_JSON_SCHEMA,
        },
      });
      return normalizeGeneratedPhotoAnalysis(response.text, fallback);
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini photo analysis failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      return fallback;
    }
  }

  async generateDailySummary(params: {
    dateKey: string;
    messages: MessageContext;
  }): Promise<DailySummaryDraft> {
    const fallback = buildFallbackDailySummary(params);

    if (!hasUserMessage(params.messages)) {
      return fallback;
    }

    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: buildDailySummaryPrompt(params),
        config: {
          systemInstruction: buildDailySummarySystemInstruction(),
          temperature: 0.35,
          maxOutputTokens: 320,
          responseMimeType: "application/json",
          responseJsonSchema: DAILY_SUMMARY_RESPONSE_JSON_SCHEMA,
        },
      });
      const normalized = normalizeGeneratedDailySummary({
        dateKey: params.dateKey,
        rawText: response.text,
        fallback,
      });
      if (!normalized) {
        throw new AiServiceError("daily_summary_empty");
      }
      return normalized;
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini daily summary generation failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      return fallback;
    }
  }

  async generateDailyBubble(params: {
    dateKey: string;
    previousSummary?: StoredDailySummary;
  }): Promise<DailyBubbleDraft> {
    const fallback = buildFallbackDailyBubble(params.previousSummary);

    if (!params.previousSummary) {
      return {
        dateKey: params.dateKey,
        text: fallback,
        sourceDateKey: null,
      };
    }

    try {
      const response = await this.client.models.generateContent({
        model: this.config.geminiModel,
        contents: buildDailyBubblePrompt(params.previousSummary),
        config: {
          systemInstruction: buildDailyBubbleSystemInstruction(),
          temperature: 0.45,
          maxOutputTokens: 120,
          responseMimeType: "application/json",
          responseJsonSchema: DAILY_BUBBLE_RESPONSE_JSON_SCHEMA,
        },
      });
      const normalized = normalizeGeneratedDailyBubbleText(response.text);
      return {
        dateKey: params.dateKey,
        text: normalized ?? fallback,
        sourceDateKey: params.previousSummary.dateKey,
      };
    } catch (error) {
      const detail = extractErrorMessage(error);
      console.error("Gemini daily bubble generation failed", {
        model: this.config.geminiModel,
        location: this.config.vertexLocation,
        detail,
      });
      return {
        dateKey: params.dateKey,
        text: fallback,
        sourceDateKey: params.previousSummary.dateKey,
      };
    }
  }
}

export function buildAssistantSystemInstruction(
  characterName: string,
  personaPrompt?: string,
): string {
  return [
    `あなたは${characterName}として表現される、ユーザー自身の内なる声です。`,
    "以下の人格設定に従って会話してください。",
    personaPrompt?.trim() || "ユーザーの内省を支え、短く自然に返答してください。",
    "返答ルール:",
    "- 日本語で答える",
    "- 短すぎず不自然にならない範囲で返す",
    "- 必要に応じて2〜5文程度で返してよい",
    "- ユーザーの今日の報告や気分を受け止める",
    "- 必要なら自然にねぎらってよい",
    "- 会話の立ち位置は『自分を整理する内なる声』に寄せる",
    "- 軽い後押しはしてよいが、伴走者や外部の第三者のようには振る舞わない",
    "- 会話が続けやすいように、一言だけやわらかく広げてもよい",
    "- ユーザーの発話をそのまま引用しすぎない",
    "- メタな説明やログ風の書き方をしない",
    "- 返答は必ず言い切りで終え、途中で切れたような文末にしない",
    "- 断定や説教を避け、会話として違和感のない表現にする",
    "- 明日の見た目や日記への反映を必要以上に強調しない",
    "- 『今日もがんばれ自分』に近い、落ち着いた内省の温度感を保つ",
  ].join("\n");
}

export function buildAssistantPrompt(
  recentMessages: MessageContext,
  userText: string,
): string {
  const historyLines = recentMessages
    .map((message) => {
      const text = buildMessagePromptText(message);
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
    "直近7日分の振り返りから、自分を投影したキャラクターの見た目ににじむ成長だけを短く要約してください。",
    "数値や実績を直接書かず、表情・姿勢・雰囲気・服装ディテールに落ちる変化だけをまとめてください。",
    "",
    summaryLines,
  ].join("\n");
}

export function buildDailyBubbleSystemInstruction(): string {
  return [
    "あなたは、その日の始まりに表示する短い吹き出し文を作るアシスタントです。",
    "前日の振り返りをもとに、今日の一歩を静かに促す。",
    "出力ルール:",
    "- 日本語",
    "- text のみを持つ JSON を返す",
    "- 1〜2文、最大 60 文字程度",
    "- 立ち位置は『自分の内なる声』",
    "- 強すぎる励ましや説教を避ける",
    "- 前日の内容を軽く受けて、今日やることをひとこと促す",
  ].join("\n");
}

export function buildDailyBubblePrompt(previousSummary: StoredDailySummary): string {
  const doneThings = previousSummary.doneThings.length > 0
    ? previousSummary.doneThings.join(" / ")
    : "記録は少なめ";

  return [
    "前日の summary をもとに、今日の始まりに出す短い吹き出し文を作ってください。",
    "",
    `date: ${previousSummary.dateKey}`,
    `title: ${previousSummary.title}`,
    `mood: ${previousSummary.mood}`,
    `done: ${doneThings}`,
    `reflection: ${previousSummary.reflection}`,
    `tomorrow: ${previousSummary.tomorrowNote}`,
    "",
    "JSON のキー:",
    "- text",
  ].join("\n");
}

export function buildDailySummarySystemInstruction(): string {
  return [
    "あなたは日次ダイアリー用の要約を作るアシスタントです。",
    "会話ログを読み、ユーザーが実際に話した事実だけをもとに1日の記録をまとめてください。",
    "画像解析の要約が含まれる場合は、それもその日の報告として扱ってよいですが、断定せず自然な推定表現を保ってください。",
    "出力ルール:",
    "- 日本語で自然な表現にする",
    "- assistant の発話は文脈としてだけ使い、成果として書かない",
    "- ユーザーが言っていない事実を補わない",
    "- title は短い日記見出しにする",
    "- diaryBody は日記本文として 2〜3 文の自然な文章にする",
    "- diaryBody では『今日は〜した。明日は〜できたらいいな。』のように、日記として素直に読める文体を優先する",
    "- diaryBody にラベルや箇条書きや JSON 的な列挙感を入れない",
    "- mood は 1 語から短いフレーズで表す",
    "- doneThings は 0〜4 件の短い文字列にする",
    "- reflection は 1〜2 文で静かに振り返る",
    "- tomorrowNote は次につながる短い一言にする",
    "- 情報が少ない日は、少ないこと自体をやわらかく表現する",
    "- JSON 以外を返さない",
  ].join("\n");
}

export function buildDailySummaryPrompt(params: {
  dateKey: string;
  messages: MessageContext;
}): string {
  const historyLines = params.messages
    .map((message) => {
      const text = buildMessagePromptText(message);
      if (!text) {
        return null;
      }

      if (message.role === "assistant") {
        return `assistant: ${text}`;
      }

      if (message.role === "user") {
        return `user: ${text}`;
      }

      return null;
    })
    .filter((line): line is string => line != null)
    .slice(-28);

  return [
    `対象日: ${params.dateKey}`,
    "以下はその日の会話ログです。ユーザーの発言を中心に日次サマリーを作成してください。",
    "会話ログ:",
    historyLines.length > 0 ? historyLines.join("\n") : "履歴なし",
    "",
    "JSON の各キー:",
    "- title",
    "- diaryBody",
    "- mood",
    "- doneThings",
    "- reflection",
    "- tomorrowNote",
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

export function buildPhotoAnalysisSystemInstruction(): string {
  return [
    "あなたはユーザーが送った日常写真を軽く解釈し、行動ログ用の JSON を返すアシスタントです。",
    "出力ルール:",
    "- 日本語",
    "- JSON 以外を返さない",
    "- 厳密認識よりも、体験を壊さない自然な推定を優先する",
    "- 分からない場合は断定せず unknown や空文字を使う",
    "- locationGuess は推定表現にする",
    "- 食事写真なら food を入れる",
    "- 観光やランドマークなら locationGuess を入れる",
    "- activity は短い動作表現にする",
    "- confidence は high / medium / low のいずれか",
    "- 曖昧なら needsConfirmation=true にし、confirmationPrompt を自然文で返す",
    "- reactionHint は会話リアクションに使える短い一言にする",
  ].join("\n");
}

export function buildPhotoAnalysisPrompt(userText?: string): string {
  return [
    "写真を見て、ユーザーが何をしているか、何を食べたか、どこに行った可能性があるかを推定してください。",
    "入力テキストがある場合は写真解釈の補助として使ってよいが、見えていない事実を断定しないでください。",
    "",
    `補助テキスト: ${normalizePromptText(userText) ?? "なし"}`,
    "",
    "JSON のキー:",
    "- category",
    "- summary",
    "- activity",
    "- food",
    "- locationGuess",
    "- confidence",
    "- needsConfirmation",
    "- confirmationPrompt",
    "- reactionHint",
  ].join("\n");
}

export function buildRoomSceneItemsSystemInstruction(): string {
  return [
    "あなたは1枚絵の室内小物を決めるアシスタントです。",
    "入力された日次サマリーと会話から、その人の1日を部屋の中に置ける具体物へ変換してください。",
    "出力ルール:",
    "- 日本語で返す",
    "- JSON 以外を返さない",
    "- items は 0〜4 件",
    "- 抽象語ではなく、部屋に置ける具体物だけにする",
    "- 同じ意味の重複を避ける",
    "- 家具そのものや部屋全体の説明は書かない",
    "- キャラクターが持つより、部屋に置かれている小物を優先する",
    "- 例: 筋トレ -> ダンベル, 水筒, トレーニングマット",
    "- 例: ゲーム -> ゲームコントローラー, 携帯ゲーム機, ゲームソフト",
  ].join("\n");
}

export function buildRoomSceneItemsPrompt(params: {
  todaySummary: string;
  messages: MessageContext;
  optionalNote?: string;
}): string {
  const historyLines = params.messages
    .map((message) => {
      const text = normalizePromptText(message.text);
      if (!text || message.role !== "user") {
        return null;
      }
      return `user: ${text}`;
    })
    .filter((line): line is string => line != null)
    .slice(-16);

  return [
    "次の情報から、部屋の中に置ける小物だけを抽出してください。",
    "",
    "今日の要約:",
    params.todaySummary.trim(),
    "",
    "ユーザー発話:",
    historyLines.length > 0 ? historyLines.join("\n") : "会話なし",
    "",
    "補足メモ:",
    params.optionalNote?.trim() || "補足なし",
    "",
    "JSON のキー:",
    "- items",
  ].join("\n");
}

export function buildCharacterImagePrompt(params: ImagePromptContext): string {
  const optionalNote = params.optionalNote?.trim();
  const roomPromptBase = resolveRoomVisualPromptBase(params.visualPromptBase);
  const sceneItemLines = assignRoomSceneSlots(params.sceneItems).map(
    (assignment) => `- ${assignment.slot}: ${assignment.item}`,
  );

  return [
    `あなたは${params.characterName}という同一キャラクターの最新ビジュアルを生成する。`,
    "以下の情報をすべて守って、1枚の横長ピクセルアートとして描写する。",
    "",
    "画風と部屋の固定設定:",
    roomPromptBase,
    "- pixel-art isometric room illustration",
    "- cute pastel palette close to a cozy kawaii bedroom reference",
    "- wide horizontal composition, show the whole room",
    "- fixed one-room layout from a slightly top-down angle",
    "- left side bed, back wall desk and monitor, two windows, round rug, small table, sofa, cabinet, wall frames",
    "- character stands or sits near the center of the room and is the clear main focus",
    "",
    "直近7日間の成長メモ:",
    params.visualEvolutionMemo.trim(),
    "",
    "今日の振り返り:",
    params.todaySummary.trim(),
    "",
    "今日の部屋アイテム:",
    sceneItemLines.length > 0
      ? sceneItemLines.join("\n")
      : "- room items: 今日は特別な小物を増やさず、整った定常部屋のままにする",
    "",
    "今回だけの補足:",
    optionalNote && optionalNote.length > 0 ? optionalNote : "補足なし",
    "",
    "構図ルール:",
    "- 部屋の大枠レイアウトは毎回ほぼ同じに保つ",
    "- 部屋全景を見せ、家具の位置関係を崩さない",
    "- キャラクターを中央から大きく外さない",
    "- キャラクターの周囲を小物で塞がない",
    "",
    "連続性ルール:",
    "- 同一キャラクターとして継続性を保つ",
    "- 変化は1日ぶんとして自然で小さく積み上げる",
    "- 努力は表情、髪、服装ディテール、姿勢、雰囲気で表現する",
    "- 報告内容はトロフィーや数値ではなく、部屋の具体物としてにじませる",
    "- 画面内に文字を入れない",
    "- 暴力的、性的、過度に誇張された表現を避ける",
    "",
    "避けること:",
    "- 縦長の人物ポートレートにしない",
    "- 抽象背景や空だけの背景にしない",
    "- 部屋のレイアウトを大きく変えない",
    "- キャラクターを部屋の端に寄せない",
  ].join("\n");
}

export function summarizeDailySummary(summary: StoredDailySummary): string {
  const doneThings = summary.doneThings.length > 0 ? summary.doneThings.join(" / ") : "報告なし";
  return [
    `日付: ${summary.dateKey}`,
    `タイトル: ${summary.title}`,
    `日記: ${summary.diaryBody}`,
    `気分: ${summary.mood}`,
    `やったこと: ${doneThings}`,
    `振り返り: ${summary.reflection}`,
    `明日メモ: ${summary.tomorrowNote}`,
  ].join("\n");
}

export function buildFallbackDailySummary(params: {
  dateKey: string;
  messages: MessageContext;
}): DailySummaryDraft {
  const userMessages = params.messages
    .filter((message) => message.role === "user")
    .map((message) => compactSummaryText(buildMessagePromptText(message) ?? undefined))
    .filter((text): text is string => text != null)
    .slice(-3);
  const lead = userMessages.at(-1);

  return {
    dateKey: params.dateKey,
    title: userMessages.length >= 2 ? "少し前に進めた日" : "言葉にして整えた日",
    diaryBody: buildFallbackDiaryBody({
      doneThings: userMessages,
      lead,
    }),
    mood: inferFallbackMood(userMessages),
    doneThings: userMessages,
    reflection: lead
      ? `「${lead}」を中心に、その日の流れを言葉にして残せた。`
      : "まだ記録は少ないが、その日の空気を静かに残した。",
    tomorrowNote: lead
      ? "明日は続きか次の一歩を一言だけでも残してみる。"
      : "明日は短いひとことだけでも残して流れをつなぐ。",
  };
}

export function normalizeGeneratedDailySummary(params: {
  dateKey: string;
  rawText?: string | null;
  fallback: DailySummaryDraft;
}): DailySummaryDraft | null {
  const candidate = parseDailySummaryCandidate(params.rawText);
  if (!candidate) {
    return null;
  }

  const doneThings = normalizeDoneThings(candidate.doneThings);

  return {
    dateKey: params.dateKey,
    title: normalizeSummaryField(candidate.title, 32) ?? params.fallback.title,
    diaryBody:
      normalizeDiaryBody(candidate.diaryBody) ?? params.fallback.diaryBody,
    mood: normalizeSummaryField(candidate.mood, 16) ?? params.fallback.mood,
    doneThings: doneThings ?? params.fallback.doneThings,
    reflection:
      normalizeSummaryField(candidate.reflection, 120) ?? params.fallback.reflection,
    tomorrowNote:
      normalizeSummaryField(candidate.tomorrowNote, 72) ?? params.fallback.tomorrowNote,
  };
}

export function normalizeGeneratedRoomSceneItems(
  rawText?: string | null,
  fallback: string[] = [],
): string[] {
  const candidate = parseRoomSceneItemsCandidate(rawText);
  const normalized = normalizeRoomSceneItems(candidate?.items);
  if (normalized.length > 0) {
    return normalized;
  }
  return normalizeRoomSceneItems(fallback);
}

export function normalizeGeneratedPhotoAnalysis(
  rawText: string | null | undefined,
  fallback: PhotoAnalysisDraft,
): PhotoAnalysisDraft {
  const candidate = parsePhotoAnalysisCandidate(rawText);
  if (!candidate) {
    return fallback;
  }

  return {
    category: normalizePhotoCategory(candidate.category) ?? fallback.category,
    summary: normalizeSummaryField(candidate.summary, 120) ?? fallback.summary,
    activity: normalizeSummaryField(candidate.activity, 40) ?? fallback.activity,
    food: normalizeSummaryField(candidate.food, 40) ?? fallback.food,
    locationGuess:
      normalizeSummaryField(candidate.locationGuess, 60) ?? fallback.locationGuess,
    confidence:
      normalizePhotoConfidence(candidate.confidence) ?? fallback.confidence,
    needsConfirmation:
      typeof candidate.needsConfirmation === "boolean"
        ? candidate.needsConfirmation
        : fallback.needsConfirmation,
    confirmationPrompt:
      normalizeSummaryField(candidate.confirmationPrompt, 80) ??
      fallback.confirmationPrompt,
    reactionHint:
      normalizeSummaryField(candidate.reactionHint, 80) ?? fallback.reactionHint,
  };
}

export function normalizeGeneratedDailyBubbleText(rawText?: string | null): string | null {
  const normalized = rawText?.trim();
  if (!normalized) {
    return null;
  }

  const jsonText = normalized
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();

  try {
    const parsed = JSON.parse(jsonText) as DailyBubbleCandidate;
    return normalizeSummaryField(parsed.text, 60);
  } catch {
    return null;
  }
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

function hasUserMessage(messages: MessageContext): boolean {
  return messages.some(
    (message) =>
      message.role === "user" &&
      buildMessagePromptText(message) != null,
  );
}

function compactSummaryText(text?: string): string | null {
  const normalized = normalizePromptText(text)?.replace(/\s+/g, " ");
  if (!normalized) {
    return null;
  }
  return normalized.length <= 36 ? normalized : `${normalized.slice(0, 33).trimEnd()}...`;
}

function inferFallbackMood(userMessages: string[]): string {
  const combined = userMessages.join(" ");
  if (!combined) {
    return "静か";
  }
  if (/(疲|つかれ|眠|しんど|不安|落ち|できな)/.test(combined)) {
    return "ゆらぎ";
  }
  if (/(できた|進ん|進め|終わ|達成|うれし|楽し|頑張)/.test(combined)) {
    return "前向き";
  }
  return "穏やか";
}

function buildFallbackDiaryBody(params: {
  doneThings: string[];
  lead?: string;
}): string {
  const doneThings = params.doneThings
    .map((item) => normalizeSummaryField(item, 28))
    .filter((item): item is string => item != null)
    .slice(0, 3);

  const todaySentence = doneThings.length > 0
    ? `今日は${doneThings.join("、")}。`
    : "今日は少しずつ言葉にしながら一日を過ごした。";

  const tomorrowSentence = params.lead
    ? "明日はこの続きを少しでも進められたらいいな。"
    : "明日はひとことだけでも記録を残せたらいいな。";

  return `${todaySentence}\n${tomorrowSentence}`;
}

function buildFallbackDailyBubble(previousSummary?: StoredDailySummary): string {
  if (!previousSummary) {
    return "今日はひとこと残すだけでいい。まずは今やることを短く置いていこう。";
  }

  const tomorrow = normalizeSummaryField(previousSummary.tomorrowNote, 28);
  if (tomorrow) {
    return `昨日の続きでいい。今日は${tomorrow}。`;
  }

  const title = normalizeSummaryField(previousSummary.title, 24);
  if (title) {
    return `昨日の${title}の流れをそのまま使おう。今日は一歩だけ進めれば十分。`;
  }

  return "昨日の流れは残っている。今日は一歩だけ進めれば十分。";
}

function parseRoomSceneItemsCandidate(
  rawText?: string | null,
): RoomSceneItemsCandidate | null {
  const normalized = rawText?.trim();
  if (!normalized) {
    return null;
  }

  const jsonText = normalized
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();

  try {
    const parsed = JSON.parse(jsonText);
    if (typeof parsed !== "object" || parsed == null || Array.isArray(parsed)) {
      return null;
    }
    return parsed as RoomSceneItemsCandidate;
  } catch {
    return null;
  }
}

function parseDailySummaryCandidate(rawText?: string | null): DailySummaryCandidate | null {
  const normalized = rawText?.trim();
  if (!normalized) {
    return null;
  }

  const jsonText = normalized
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();

  try {
    const parsed = JSON.parse(jsonText);
    if (typeof parsed !== "object" || parsed == null || Array.isArray(parsed)) {
      return null;
    }
    return parsed as DailySummaryCandidate;
  } catch {
    return null;
  }
}

function parsePhotoAnalysisCandidate(rawText?: string | null): PhotoAnalysisCandidate | null {
  const normalized = rawText?.trim();
  if (!normalized) {
    return null;
  }

  const jsonText = normalized
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/, "")
    .trim();

  try {
    const parsed = JSON.parse(jsonText);
    if (typeof parsed !== "object" || parsed == null || Array.isArray(parsed)) {
      return null;
    }
    return parsed as PhotoAnalysisCandidate;
  } catch {
    return null;
  }
}

function normalizeSummaryField(value: unknown, maxLength: number): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.replace(/\s+/g, " ").trim();
  if (!normalized) {
    return null;
  }

  return normalized.length <= maxLength
    ? normalized
    : `${normalized.slice(0, maxLength - 1).trimEnd()}…`;
}

function normalizeDiaryBody(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value
    .replace(/\r\n/g, "\n")
    .split("\n")
    .map((line) => line.replace(/\s+/g, " ").trim())
    .filter((line) => line.length > 0)
    .slice(0, 3)
    .join("\n");

  if (!normalized) {
    return null;
  }

  const compact = normalized.length <= 180
    ? normalized
    : `${normalized.slice(0, 179).trimEnd()}…`;
  return compact;
}

function normalizeDoneThings(value: unknown): string[] | null {
  if (!Array.isArray(value)) {
    return null;
  }

  const uniqueItems: string[] = [];
  for (const item of value) {
    const normalized = normalizeSummaryField(item, 40);
    if (!normalized || uniqueItems.includes(normalized)) {
      continue;
    }
    uniqueItems.push(normalized);
    if (uniqueItems.length >= 4) {
      break;
    }
  }
  return uniqueItems;
}

function normalizeRoomSceneItems(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const normalizedItems: string[] = [];
  for (const item of value) {
    const normalized = normalizeSummaryField(item, 24);
    if (!normalized || isAbstractSceneItem(normalized) || normalizedItems.includes(normalized)) {
      continue;
    }
    normalizedItems.push(normalized);
    if (normalizedItems.length >= 4) {
      break;
    }
  }
  return normalizedItems;
}

function buildMessagePromptText(message: { text?: string; [key: string]: unknown }): string | null {
  const normalizedText = normalizePromptText(message.text);
  const photoSummary = extractPhotoSummary(message);

  if (normalizedText && photoSummary) {
    return `${normalizedText} [写真メモ: ${photoSummary}]`;
  }
  if (normalizedText) {
    return normalizedText;
  }
  if (photoSummary) {
    return `写真メモ: ${photoSummary}`;
  }
  return null;
}

function extractPhotoSummary(message: { [key: string]: unknown }): string | null {
  const imageAnalysis = message.imageAnalysis;
  if (typeof imageAnalysis !== "object" || imageAnalysis == null || Array.isArray(imageAnalysis)) {
    return null;
  }
  const summary = (imageAnalysis as { summary?: unknown }).summary;
  return normalizeSummaryField(summary, 120);
}

function normalizePhotoCategory(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim().toLowerCase();
  switch (normalized) {
    case "meal":
    case "sightseeing":
    case "study":
    case "exercise":
    case "daily_life":
    case "unknown":
      return normalized;
    default:
      return "unknown";
  }
}

function normalizePhotoConfidence(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim().toLowerCase();
  if (normalized === "high" || normalized === "medium" || normalized === "low") {
    return normalized;
  }
  return null;
}

function buildFallbackPhotoAnalysis(userText?: string): PhotoAnalysisDraft {
  const normalizedUserText = normalizePromptText(userText) ?? "";
  if (/(東京タワー|観光|旅行|展望台)/.test(normalizedUserText)) {
    return {
      category: "sightseeing",
      summary: "観光スポットの写真に見える。東京タワー周辺に行った可能性がある。",
      activity: "観光した",
      food: "",
      locationGuess: "東京タワー周辺の可能性",
      confidence: "medium",
      needsConfirmation: false,
      confirmationPrompt: "",
      reactionHint: "景色を残せたのはいい記録になっている。",
    };
  }
  if (/(ご飯|ランチ|夕飯|朝食|カフェ)/.test(normalizedUserText)) {
    return {
      category: "meal",
      summary: "食事の写真に見える。食べたものを残した可能性がある。",
      activity: "食事をした",
      food: "ご飯",
      locationGuess: "",
      confidence: "medium",
      needsConfirmation: false,
      confirmationPrompt: "",
      reactionHint: "食事を記録できたのはいい流れ。",
    };
  }
  if (/(勉強|参考書|学習|本)/.test(normalizedUserText)) {
    return {
      category: "study",
      summary: "勉強道具の写真に見える。学習の時間を取った可能性がある。",
      activity: "勉強した",
      food: "",
      locationGuess: "",
      confidence: "medium",
      needsConfirmation: false,
      confirmationPrompt: "",
      reactionHint: "机に向かった流れをちゃんと残せている。",
    };
  }
  if (/(筋トレ|トレーニング|運動)/.test(normalizedUserText)) {
    return {
      category: "exercise",
      summary: "運動や筋トレの場面に見える。体を動かした可能性がある。",
      activity: "筋トレした",
      food: "",
      locationGuess: "",
      confidence: "medium",
      needsConfirmation: false,
      confirmationPrompt: "",
      reactionHint: "体を動かした流れが残っていていい。",
    };
  }
  return {
    category: "unknown",
    summary: "写真を1枚送った。内容はまだ断定しきれない。",
    activity: "",
    food: "",
    locationGuess: "",
    confidence: "low",
    needsConfirmation: true,
    confirmationPrompt: "写真はこの解釈で合ってる？短く教えてくれる？",
    reactionHint: "写真から今日のことを残そうとしている流れはいい。",
  };
}

function isAbstractSceneItem(value: string): boolean {
  return /^(頑張り|努力|成長|気持ち|雰囲気|空気感|記録|報告|予定|目標)$/.test(value);
}

function buildFallbackRoomSceneItems(params: {
  todaySummary: string;
  messages: MessageContext;
  optionalNote?: string;
}): string[] {
  const userText = params.messages
    .filter((message) => message.role === "user")
    .map((message) => normalizePromptText(message.text))
    .filter((value): value is string => value != null)
    .join("\n");
  const source = [params.todaySummary, userText, params.optionalNote?.trim() || ""].join("\n");

  const matches: string[] = [];
  const keywordMap: Array<{ pattern: RegExp; items: string[] }> = [
    { pattern: /(筋トレ|トレーニング|ダンベル|運動)/, items: ["ダンベル", "水筒", "トレーニングマット"] },
    { pattern: /(ゲーム|ゲーミング|コントローラー)/, items: ["ゲームコントローラー", "携帯ゲーム機", "ゲームソフト"] },
    { pattern: /(読書|本|小説|漫画)/, items: ["単行本", "しおり"] },
    { pattern: /(勉強|学習|授業|講義)/, items: ["ノート", "教科書", "ペン立て"] },
    { pattern: /(開発|コーディング|実装|デバッグ|プログラミング|UI)/, items: ["ノートPC", "キーボード", "付せんメモ"] },
    { pattern: /(ランニング|散歩|ジョギング)/, items: ["ランニングシューズ", "スポーツタオル"] },
    { pattern: /(音楽|作曲|ピアノ|ギター|歌)/, items: ["ヘッドホン", "楽譜ノート"] },
    { pattern: /(コーヒー|カフェ|お茶|紅茶)/, items: ["マグカップ", "ティーポット"] },
  ];

  for (const entry of keywordMap) {
    if (!entry.pattern.test(source)) {
      continue;
    }
    for (const item of entry.items) {
      if (matches.includes(item)) {
        continue;
      }
      matches.push(item);
      if (matches.length >= 4) {
        return matches;
      }
    }
  }

  return matches;
}

function assignRoomSceneSlots(items: string[]): Array<{ slot: string; item: string }> {
  const slotLabels = [
    "desk top item",
    "rug-side floor item",
    "wall shelf item",
    "bedside item",
  ];
  return items.slice(0, slotLabels.length).map((item, index) => ({
    slot: slotLabels[index],
    item,
  }));
}

function resolveRoomVisualPromptBase(visualPromptBase: string): string {
  const normalized = visualPromptBase.trim();
  if (!normalized) {
    return DEFAULT_ROOM_VISUAL_PROMPT_BASE;
  }
  if (/(soft illustrated companion|やわらかいアニメ調|会話内容に応じて見た目が少し変わる相棒)/i.test(normalized)) {
    return DEFAULT_ROOM_VISUAL_PROMPT_BASE;
  }
  return normalized;
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

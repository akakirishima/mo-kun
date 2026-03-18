import { randomUUID } from "node:crypto";
import { AppRepository } from "../repositories/app-repository.js";
import { AiService } from "./ai-service.js";
import { ImageDraft, StoredDailySummary } from "../types.js";
import { buildAppDateKey } from "./app-date.js";

export class CharacterImageService {
  constructor(
    private readonly repository: AppRepository,
    private readonly aiService: AiService,
    private readonly imageStore: ImageStore,
  ) {}

  async generateAndPersist(params: {
    userId: string;
    title: string;
    optionalNote?: string;
    todaySummary?: StoredDailySummary;
    now?: Date;
  }): Promise<ImageDraft> {
    const character = await this.repository.getCharacterContext(params.userId);
    if (!character) {
      throw new Error("character_not_found");
    }

    const now = params.now ?? new Date();
    const targetDateKey = params.todaySummary?.dateKey ?? buildAppDateKey(now);
    const dayMessages = await this.repository.getMessagesForDateKey(
      `${params.userId}_main`,
      targetDateKey,
    );
    const recentSummaries = await this.repository.listRecentDailySummaries(
      params.userId,
      7,
    );
    const visualEvolutionMemo = await this.aiService.generateVisualEvolutionMemo({
      recentSummaries,
    });
    await this.repository.markCharacterImageGenerating({
      userId: params.userId,
      visualEvolutionMemo,
    });

    const todaySummaryText = await this.resolveTodaySummaryText({
      todaySummary: params.todaySummary,
      recentSummaries,
      now,
      dayMessages,
    });
    const sceneItems = await this.aiService.generateRoomSceneItems({
      todaySummary: todaySummaryText,
      messages: dayMessages,
      optionalNote: params.optionalNote,
    });
    const prompt = this.aiService.buildCharacterImagePrompt({
      characterName: String(character.name ?? "Self"),
      visualPromptBase: String(character.visualPromptBase ?? ""),
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
      sceneItems,
      optionalNote: params.optionalNote,
    });
    const promptExcerpt = buildPromptExcerpt({
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
      sceneItems,
      optionalNote: params.optionalNote,
    });

    try {
      const generated = await this.aiService.generateCharacterImage({ prompt });
      const imageUrl = await this.imageStore.save({
        userId: params.userId,
        bytes: generated.imageBytes,
        mimeType: generated.mimeType,
      });
      const image = {
        title: params.title,
        promptExcerpt,
        imageUrl,
        dateKey: targetDateKey,
      };

      await this.repository.saveCharacterImage({
        userId: params.userId,
        image,
        status: "ready",
        visualEvolutionMemo,
        dateKey: targetDateKey,
      });
      return image;
    } catch (error) {
      await this.repository.saveCharacterImage({
        userId: params.userId,
        image: {
          title: params.title,
          promptExcerpt,
          imageUrl: null,
          dateKey: targetDateKey,
        },
        status: "failed",
        visualEvolutionMemo,
        dateKey: targetDateKey,
      });
      throw error;
    }
  }

  private async resolveTodaySummaryText(params: {
    recentSummaries: StoredDailySummary[];
    todaySummary?: StoredDailySummary;
    now: Date;
    dayMessages: Array<{ role?: string; text?: string }>;
  }) {
    if (params.todaySummary) {
      return summarizeDailySummaryForImage(params.todaySummary);
    }

    const targetDateKey = buildAppDateKey(params.now);
    const matchingSummary = params.recentSummaries.find(
      (summary) => summary.dateKey === targetDateKey,
    );
    if (matchingSummary) {
      return summarizeDailySummaryForImage(matchingSummary);
    }

    if (params.dayMessages.length === 0) {
      return "今日の報告はまだ少なく、始まりの雰囲気を保っている。";
    }

    const fallbackSummary = await this.aiService.generateDailySummary({
      dateKey: targetDateKey,
      messages: params.dayMessages,
    });
    return summarizeDailySummaryForImage(fallbackSummary);
  }
}

export type ImageStore = {
  save(params: {
    userId: string;
    bytes: Buffer;
    mimeType: string;
  }): Promise<string>;
};

type WritableBucket = {
  name: string;
  file(path: string): {
    save(
      data: Buffer,
      options: {
        contentType: string;
        resumable: boolean;
        metadata: {
          metadata: {
            firebaseStorageDownloadTokens: string;
          };
        };
      },
    ): Promise<void>;
  };
};

export class CloudStorageImageStore implements ImageStore {
  constructor(private readonly bucket: WritableBucket) {}

  async save(params: {
    userId: string;
    bytes: Buffer;
    mimeType: string;
  }): Promise<string> {
    const extension = mimeTypeToExtension(params.mimeType);
    const filePath = `characters/${params.userId}/imageHistory/${Date.now()}-${randomUUID()}.${extension}`;
    const file = this.bucket.file(filePath);

    await file.save(params.bytes, {
      contentType: params.mimeType,
      resumable: false,
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: randomUUID(),
        },
      },
    });

    return `gs://${this.bucket.name}/${filePath}`;
  }
}

export function summarizeDailySummaryForImage(summary: StoredDailySummary): string {
  const doneThings = summary.doneThings.length > 0
    ? summary.doneThings.join(" / ")
    : "報告なし";

  return [
    `日付: ${summary.dateKey}`,
    `気分: ${summary.mood}`,
    `やったこと: ${doneThings}`,
    `振り返り: ${summary.reflection}`,
    `明日メモ: ${summary.tomorrowNote}`,
  ].join("\n");
}

export function buildPromptExcerpt(params: {
  visualEvolutionMemo: string;
  todaySummary: string;
  sceneItems: string[];
  optionalNote?: string;
}): string {
  const excerpt = [
    `growth=${params.visualEvolutionMemo.trim()}`,
    `today=${params.todaySummary.replace(/\n/g, " ").trim()}`,
    params.sceneItems.length > 0
      ? `roomItems=${params.sceneItems.join(", ")}`
      : null,
    params.optionalNote?.trim()
      ? `note=${params.optionalNote.trim()}`
      : null,
  ]
    .filter((value): value is string => value != null && value.length > 0)
    .join(" / ");

  return excerpt.length <= 500 ? excerpt : `${excerpt.slice(0, 497).trimEnd()}...`;
}

function mimeTypeToExtension(mimeType: string) {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/jpeg":
      return "jpg";
    case "image/webp":
      return "webp";
    default:
      return "bin";
  }
}

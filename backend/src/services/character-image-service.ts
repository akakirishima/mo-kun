import { randomUUID } from "node:crypto";
import { AppRepository } from "../repositories/app-repository.js";
import { AiService } from "./ai-service.js";
import { ImageDraft, StoredDailySummary } from "../types.js";

const DAY_IN_MS = 24 * 60 * 60 * 1000;

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
      userId: params.userId,
      todaySummary: params.todaySummary,
      recentSummaries,
      now,
    });
    const prompt = this.aiService.buildCharacterImagePrompt({
      characterName: String(character.name ?? "Mori"),
      visualPromptBase: String(character.visualPromptBase ?? ""),
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
      optionalNote: params.optionalNote,
    });
    const promptExcerpt = buildPromptExcerpt({
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
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
      };

      await this.repository.saveCharacterImage({
        userId: params.userId,
        image,
        status: "ready",
        visualEvolutionMemo,
      });
      return image;
    } catch (error) {
      await this.repository.saveCharacterImage({
        userId: params.userId,
        image: {
          title: params.title,
          promptExcerpt,
          imageUrl: null,
        },
        status: "failed",
        visualEvolutionMemo,
      });
      throw error;
    }
  }

  private async resolveTodaySummaryText(params: {
    userId: string;
    recentSummaries: StoredDailySummary[];
    todaySummary?: StoredDailySummary;
    now: Date;
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

    const messages = await this.repository.getRecentMessages(
      `${params.userId}_main`,
      20,
    );
    if (messages.length === 0) {
      return "今日の報告はまだ少なく、始まりの雰囲気を保っている。";
    }

    const fallbackSummary = this.aiService.generateDailySummary({
      dateKey: targetDateKey,
      messages,
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

export function buildAppDateKey(now: Date): string {
  const adjusted = now.getHours() < 3 ? new Date(now.getTime() - DAY_IN_MS) : now;
  const year = adjusted.getFullYear();
  const month = `${adjusted.getMonth() + 1}`.padStart(2, "0");
  const day = `${adjusted.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
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
  optionalNote?: string;
}): string {
  const excerpt = [
    `growth=${params.visualEvolutionMemo.trim()}`,
    `today=${params.todaySummary.replace(/\n/g, " ").trim()}`,
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

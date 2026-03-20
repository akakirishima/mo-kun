import { randomUUID } from "node:crypto";
import { AppRepository } from "../repositories/app-repository.js";
import { AiService } from "./ai-service.js";
import { ImageDraft, StoredDailySummary, VideoDraft } from "../types.js";
import { buildAppDateKey } from "./app-date.js";

export class CharacterImageService {
  constructor(
    private readonly repository: AppRepository,
    private readonly aiService: AiService,
    private readonly imageStore: ImageStore,
    private readonly videoStore: VideoStore,
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

    const motionPrompt = this.aiService.buildCharacterMotionPrompt({
      characterName: String(character.name ?? "Self"),
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
      sceneItems,
      optionalNote: params.optionalNote,
    });
    const motionPromptExcerpt = buildMotionPromptExcerpt({
      visualEvolutionMemo,
      todaySummary: todaySummaryText,
      sceneItems,
      optionalNote: params.optionalNote,
    });

    const generatedImage = await this.aiService.generateCharacterImage({ prompt });
    const imageUrl = await this.imageStore.save({
      userId: params.userId,
      bytes: generatedImage.imageBytes,
      mimeType: generatedImage.mimeType,
    });

    const image: ImageDraft = {
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

    await this.repository.markCharacterVideoGenerating({
      userId: params.userId,
      posterImageUrl: imageUrl,
    });

    let latestVideoUrl: string | null = null;
    let videoStatus: "ready" | "failed" = "failed";

    try {
      const generatedVideo = await this.aiService.generateCharacterMotionVideo({
        imageBytes: generatedImage.imageBytes,
        mimeType: generatedImage.mimeType,
        prompt: motionPrompt,
        outputGcsUri: this.videoStore.buildOutputGcsUri({
          userId: params.userId,
          prefix: targetDateKey,
        }),
      });
      latestVideoUrl = await this.videoStore.save({
        userId: params.userId,
        bytes: generatedVideo.videoBytes,
        mimeType: generatedVideo.mimeType,
        generatedUri: generatedVideo.uri,
      });
      videoStatus = "ready";

      const video: VideoDraft = {
        title: `${params.title}の動画`,
        promptExcerpt: motionPromptExcerpt,
        videoUrl: latestVideoUrl,
        posterImageUrl: imageUrl,
        dateKey: targetDateKey,
      };
      await this.repository.saveCharacterVideo({
        userId: params.userId,
        video,
        status: "ready",
        sourceImageUrl: imageUrl,
      });
    } catch (error) {
      console.error("Character motion video generation failed", {
        userId: params.userId,
        detail: error instanceof Error ? error.message : "unknown_error",
      });
      await this.repository.saveCharacterVideo({
        userId: params.userId,
        video: {
          title: `${params.title}の動画`,
          promptExcerpt: motionPromptExcerpt,
          videoUrl: null,
          posterImageUrl: imageUrl,
          dateKey: targetDateKey,
        },
        status: "failed",
        sourceImageUrl: imageUrl,
      });
    }

    return {
      ...image,
      latestVideoUrl,
      posterImageUrl: imageUrl,
      videoStatus,
    };
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
  load(params: { sourceUrl: string }): Promise<{ bytes: Buffer; mimeType: string }>;
};

export type VideoStore = {
  buildOutputGcsUri(params: { userId: string; prefix?: string }): string;
  save(params: {
    userId: string;
    bytes?: Buffer;
    mimeType: string;
    generatedUri?: string;
  }): Promise<string>;
};

export type ChatPhotoStore = {
  save(params: {
    userId: string;
    threadId: string;
    bytes: Buffer;
    mimeType: string;
  }): Promise<{ imageUrl: string; storagePath: string }>;
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
    download(): Promise<[Buffer]>;
    getMetadata(): Promise<[Record<string, unknown>, unknown?]>;
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
    const filePath =
      `characters/${params.userId}/imageHistory/${Date.now()}-${randomUUID()}.${extension}`;
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

  async load(params: { sourceUrl: string }): Promise<{ bytes: Buffer; mimeType: string }> {
    const { bucketName, filePath } = parseGsUrl(params.sourceUrl);
    if (bucketName !== this.bucket.name) {
      throw new Error(`bucket_mismatch: ${bucketName}`);
    }
    const file = this.bucket.file(filePath);
    const [bytes] = await file.download();
    const [metadata] = await file.getMetadata();
    return {
      bytes,
      mimeType: String(metadata.contentType ?? "image/png"),
    };
  }
}

export class CloudStorageVideoStore implements VideoStore {
  constructor(private readonly bucket: WritableBucket) {}

  buildOutputGcsUri(params: { userId: string; prefix?: string }): string {
    const suffix = params.prefix?.trim() ? `/${params.prefix.trim()}` : "";
    return `gs://${this.bucket.name}/characters/${params.userId}/videoHistory${suffix}`;
  }

  async save(params: {
    userId: string;
    bytes?: Buffer;
    mimeType: string;
    generatedUri?: string;
  }): Promise<string> {
    if (params.generatedUri && params.generatedUri.trim().length > 0) {
      return params.generatedUri;
    }
    if (!params.bytes || params.bytes.length === 0) {
      throw new Error("video_bytes_missing");
    }

    const extension = mimeTypeToExtension(params.mimeType);
    const filePath =
      `characters/${params.userId}/videoHistory/${Date.now()}-${randomUUID()}.${extension}`;
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

export class CloudStorageChatPhotoStore implements ChatPhotoStore {
  constructor(private readonly bucket: WritableBucket) {}

  async save(params: {
    userId: string;
    threadId: string;
    bytes: Buffer;
    mimeType: string;
  }): Promise<{ imageUrl: string; storagePath: string }> {
    const extension = mimeTypeToExtension(params.mimeType);
    const filePath =
      `chatUploads/${params.userId}/${params.threadId}/${Date.now()}-${randomUUID()}.${extension}`;
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

    return {
      imageUrl: `gs://${this.bucket.name}/${filePath}`,
      storagePath: filePath,
    };
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

export function buildMotionPromptExcerpt(params: {
  visualEvolutionMemo: string;
  todaySummary: string;
  sceneItems: string[];
  optionalNote?: string;
}): string {
  const excerpt = [
    `motionGrowth=${params.visualEvolutionMemo.trim()}`,
    `motionToday=${params.todaySummary.replace(/\n/g, " ").trim()}`,
    params.sceneItems.length > 0
      ? `motionRoomItems=${params.sceneItems.join(", ")}`
      : null,
    params.optionalNote?.trim()
      ? `motionNote=${params.optionalNote.trim()}`
      : null,
  ]
    .filter((value): value is string => value != null && value.length > 0)
    .join(" / ");

  return excerpt.length <= 500 ? excerpt : `${excerpt.slice(0, 497).trimEnd()}...`;
}

function parseGsUrl(sourceUrl: string) {
  const match = /^gs:\/\/([^/]+)\/(.+)$/.exec(sourceUrl.trim());
  if (!match) {
    throw new Error(`invalid_gs_url: ${sourceUrl}`);
  }
  return {
    bucketName: match[1],
    filePath: match[2],
  };
}

function mimeTypeToExtension(mimeType: string) {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/jpeg":
      return "jpg";
    case "image/webp":
      return "webp";
    case "video/mp4":
      return "mp4";
    default:
      return "bin";
  }
}

import { randomUUID } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { AppRepository } from "../repositories/app-repository.js";
import { AiService } from "./ai-service.js";
import {
  AppearancePresetValue,
  CharacterGenderValue,
  ImageDraft,
  StoredDailySummary,
  VideoDraft,
} from "../types.js";
import { buildAppDateKey } from "./app-date.js";

const execFileAsync = promisify(execFile);

export class CharacterImageService {
  constructor(
    private readonly repository: AppRepository,
    private readonly aiService: AiService,
    private readonly imageStore: ImageStore,
    private readonly videoStore: VideoStore,
    private readonly videoProcessor: VideoProcessor,
  ) {}

  async generateAndPersist(params: {
    userId: string;
    title: string;
    optionalNote?: string;
    todaySummary?: StoredDailySummary;
    now?: Date;
  }): Promise<ImageDraft> {
    const [character, userProfile] = await Promise.all([
      this.repository.getCharacterContext(params.userId),
      this.repository.getUserProfileContext(params.userId),
    ]);
    if (!character) {
      throw new Error("character_not_found");
    }
    const appearancePreset = normalizeAppearancePreset(userProfile?.appearancePreset);
    const characterGender = normalizeCharacterGender(userProfile?.characterGender);
    const age = normalizeCharacterAge(userProfile?.age);

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
      age,
      characterGender,
      appearancePreset,
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
      age,
      characterGender,
      appearancePreset,
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

    let latestVideoUrl =
      typeof character.lastGeneratedVideoUrl === "string"
        ? character.lastGeneratedVideoUrl
        : null;
    let latestSquareVideoUrl =
      typeof character.lastGeneratedSquareVideoUrl === "string"
        ? character.lastGeneratedSquareVideoUrl
        : null;
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

      const sourceVideo = generatedVideo.videoBytes && generatedVideo.videoBytes.length > 0
        ? {
            bytes: generatedVideo.videoBytes,
            mimeType: generatedVideo.mimeType,
          }
        : latestVideoUrl
        ? await this.videoStore.load({ sourceUrl: latestVideoUrl })
        : null;

      if (!sourceVideo) {
        throw new Error("generated_video_source_missing");
      }

      try {
        const squareVideo = await this.videoProcessor.createSquareVariant({
          videoBytes: sourceVideo.bytes,
          mimeType: sourceVideo.mimeType,
        });
        latestSquareVideoUrl = await this.videoStore.save({
          userId: params.userId,
          bytes: squareVideo.videoBytes,
          mimeType: squareVideo.mimeType,
          variant: "square",
        });
      } catch (error) {
        const debugInfo =
          error instanceof SquareVariantProcessingError ? error.debugInfo : undefined;
        console.error("Character motion square crop failed", {
          userId: params.userId,
          rawVideoUrl: latestVideoUrl,
          contentRect: formatCropDebugRect(debugInfo?.contentRect, debugInfo?.detection),
          squareRect: formatCropDebugRect(debugInfo?.squareRect),
          detail: error instanceof Error ? error.message : "unknown_error",
        });
      }

      videoStatus = "ready";

      const video: VideoDraft = {
        title: `${params.title}の動画`,
        promptExcerpt: motionPromptExcerpt,
        videoUrl: latestVideoUrl,
        squareVideoUrl: latestSquareVideoUrl,
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
          squareVideoUrl: null,
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
      latestSquareVideoUrl,
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
    variant?: string;
  }): Promise<string>;
  load(params: { sourceUrl: string }): Promise<{ bytes: Buffer; mimeType: string }>;
};

export type VideoProcessor = {
  createSquareVariant(params: {
    videoBytes: Buffer;
    mimeType: string;
  }): Promise<{ videoBytes: Buffer; mimeType: string; debugInfo?: SquareVariantDebugInfo }>;
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
    variant?: string;
  }): Promise<string> {
    if (params.generatedUri && params.generatedUri.trim().length > 0) {
      return params.generatedUri;
    }
    if (!params.bytes || params.bytes.length === 0) {
      throw new Error("video_bytes_missing");
    }

    const extension = mimeTypeToExtension(params.mimeType);
    const variantSuffix = normalizeStorageVariant(params.variant);
    const filePath =
      `characters/${params.userId}/videoHistory/${Date.now()}${variantSuffix}-${randomUUID()}.${extension}`;
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
      mimeType: String(metadata.contentType ?? "video/mp4"),
    };
  }
}

export class FfmpegVideoProcessor implements VideoProcessor {
  async createSquareVariant(params: {
    videoBytes: Buffer;
    mimeType: string;
  }): Promise<{ videoBytes: Buffer; mimeType: string; debugInfo?: SquareVariantDebugInfo }> {
    const tempDirectory = await mkdtemp(join(tmpdir(), "mo-kun-video-"));
    const inputPath = join(
      tempDirectory,
      `input.${mimeTypeToExtension(params.mimeType)}`,
    );
    const outputPath = join(tempDirectory, "square.mp4");
    let debugInfo: SquareVariantDebugInfo | undefined;

    try {
      await writeFile(inputPath, params.videoBytes);
      const dimensions = await probeVideoDimensions(inputPath);
      const cropdetectOutput = await runCropdetect(inputPath);
      debugInfo = resolveSquareVariantDebugInfo({
        inputWidth: dimensions.width,
        inputHeight: dimensions.height,
        cropdetectOutput,
      });
      await execFileAsync("ffmpeg", [
        "-y",
        "-loglevel",
        "error",
        "-i",
        inputPath,
        "-vf",
        formatCropFilter(debugInfo.squareRect),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        "-an",
        outputPath,
      ]);
      const videoBytes = await readFile(outputPath);
      return {
        videoBytes,
        mimeType: "video/mp4",
        debugInfo,
      };
    } catch (error) {
      throw new SquareVariantProcessingError(extractProcessErrorDetail(error), debugInfo);
    } finally {
      await rm(tempDirectory, { recursive: true, force: true });
    }
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

export type VideoCropRect = {
  width: number;
  height: number;
  x: number;
  y: number;
};

export type SquareVariantDebugInfo = {
  inputRect: VideoCropRect;
  contentRect: VideoCropRect;
  squareRect: VideoCropRect;
  detection: "detected" | "full_frame" | "unstable";
  candidateCount: number;
};

export class SquareVariantProcessingError extends Error {
  constructor(
    message: string,
    readonly debugInfo?: SquareVariantDebugInfo,
  ) {
    super(message);
    this.name = "SquareVariantProcessingError";
  }
}

export function parseCropdetectCandidates(output: string): VideoCropRect[] {
  const candidates: VideoCropRect[] = [];
  const matcher = /crop=(\d+):(\d+):(\d+):(\d+)/g;
  let match: RegExpExecArray | null;

  while ((match = matcher.exec(output)) != null) {
    candidates.push({
      width: Number.parseInt(match[1], 10),
      height: Number.parseInt(match[2], 10),
      x: Number.parseInt(match[3], 10),
      y: Number.parseInt(match[4], 10),
    });
  }

  return candidates;
}

export function resolveSquareVariantDebugInfo(params: {
  inputWidth: number;
  inputHeight: number;
  cropdetectOutput: string;
}): SquareVariantDebugInfo {
  const inputRect: VideoCropRect = {
    width: params.inputWidth,
    height: params.inputHeight,
    x: 0,
    y: 0,
  };
  const candidates = parseCropdetectCandidates(params.cropdetectOutput);
  const detectedRect = pickLargestValidCropRect({
    candidates,
    inputRect,
  });
  const stableDetectedRect =
    detectedRect != null && isStableBlackBarCrop({ inputRect, contentRect: detectedRect })
      ? detectedRect
      : null;
  const detection: SquareVariantDebugInfo["detection"] =
    stableDetectedRect != null
      ? "detected"
      : detectedRect != null
      ? "unstable"
      : "full_frame";
  const contentRect = stableDetectedRect ?? inputRect;

  return {
    inputRect,
    contentRect,
    squareRect: computeCenteredSquareRect(contentRect),
    detection,
    candidateCount: candidates.length,
  };
}

function normalizeAppearancePreset(value: unknown): AppearancePresetValue | undefined {
  switch (value) {
    case "blossom":
    case "sky":
    case "forest":
    case "sunset":
      return value;
    default:
      return undefined;
  }
}

function normalizeCharacterGender(value: unknown): CharacterGenderValue | undefined {
  switch (value) {
    case "female":
    case "male":
    case "non_binary":
      return value;
    default:
      return undefined;
  }
}

function normalizeCharacterAge(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
  }
  return undefined;
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

function normalizeStorageVariant(variant?: string) {
  const normalized = variant?.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, "-");
  return normalized && normalized.length > 0 ? `-${normalized}` : "";
}

async function probeVideoDimensions(inputPath: string) {
  const { stdout } = await execFileAsync(
    "ffprobe",
    [
      "-v",
      "error",
      "-select_streams",
      "v:0",
      "-show_entries",
      "stream=width,height",
      "-of",
      "csv=p=0:s=x",
      inputPath,
    ],
    { maxBuffer: 1024 * 1024 },
  );
  const match = /^(\d+)x(\d+)$/.exec(String(stdout).trim());
  if (!match) {
    throw new Error("video_dimensions_probe_failed");
  }
  return {
    width: Number.parseInt(match[1], 10),
    height: Number.parseInt(match[2], 10),
  };
}

async function runCropdetect(inputPath: string) {
  const { stderr } = await execFileAsync(
    "ffmpeg",
    [
      "-hide_banner",
      "-loglevel",
      "info",
      "-i",
      inputPath,
      "-vf",
      "cropdetect=limit=0.03:round=2:reset=0",
      "-frames:v",
      "90",
      "-f",
      "null",
      "-",
    ],
    { maxBuffer: 8 * 1024 * 1024 },
  );
  return stringifyProcessOutput(stderr);
}

function pickLargestValidCropRect(params: {
  candidates: VideoCropRect[];
  inputRect: VideoCropRect;
}) {
  const validCandidates = params.candidates.filter((candidate) => {
    if (candidate.width <= 0 || candidate.height <= 0) {
      return false;
    }
    if (candidate.x < 0 || candidate.y < 0) {
      return false;
    }
    if (candidate.width > params.inputRect.width || candidate.height > params.inputRect.height) {
      return false;
    }
    return (
      candidate.x + candidate.width <= params.inputRect.width &&
      candidate.y + candidate.height <= params.inputRect.height
    );
  });

  return validCandidates.sort((left, right) => {
    const areaDelta = right.width * right.height - left.width * left.height;
    if (areaDelta !== 0) {
      return areaDelta;
    }
    const topDelta = left.y - right.y;
    if (topDelta !== 0) {
      return topDelta;
    }
    return left.x - right.x;
  })[0] ?? null;
}

function isStableBlackBarCrop(params: {
  inputRect: VideoCropRect;
  contentRect: VideoCropRect;
}) {
  const heightRetention = params.contentRect.height / params.inputRect.height;
  const widthRetention = params.contentRect.width / params.inputRect.width;
  return heightRetention >= 0.9 && widthRetention >= 0.5;
}

function computeCenteredSquareRect(contentRect: VideoCropRect): VideoCropRect {
  const side = Math.min(contentRect.width, contentRect.height);
  return {
    width: side,
    height: side,
    x: contentRect.x + Math.floor((contentRect.width - side) / 2),
    y: contentRect.y + Math.floor((contentRect.height - side) / 2),
  };
}

function formatCropFilter(rect: VideoCropRect) {
  return `crop=${rect.width}:${rect.height}:${rect.x}:${rect.y}`;
}

function extractProcessErrorDetail(error: unknown) {
  if (typeof error === "object" && error != null) {
    const stderr = "stderr" in error
      ? stringifyProcessOutput((error as { stderr?: string | Buffer }).stderr)
      : "";
    const message = "message" in error ? String((error as { message?: unknown }).message ?? "") : "";
    return stderr || message || "ffmpeg_square_crop_failed";
  }
  return "ffmpeg_square_crop_failed";
}

function stringifyProcessOutput(output: string | Buffer | undefined) {
  if (typeof output === "string") {
    return output.trim();
  }
  if (Buffer.isBuffer(output)) {
    return output.toString("utf8").trim();
  }
  return "";
}

function formatCropDebugRect(
  rect?: VideoCropRect,
  detection?: SquareVariantDebugInfo["detection"],
) {
  if (!rect) {
    return detection === "full_frame" || detection === "unstable" ? detection : "undetected";
  }
  const label = detection ? `${detection}:` : "";
  return `${label}${rect.width}x${rect.height}+${rect.x}+${rect.y}`;
}

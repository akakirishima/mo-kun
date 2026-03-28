import assert from "node:assert/strict";
import {
  buildMotionPromptExcerpt,
  buildPromptExcerpt,
  CharacterImageService,
  parseCropdetectCandidates,
  resolveSquareVariantDebugInfo,
} from "./character-image-service.js";
import { buildAppDateKey, buildAppDateWindow } from "./app-date.js";
import { StoredDailySummary } from "../types.js";

class FakeRepository {
  character = {
    name: "Mori",
    visualPromptBase: "soft illustrated companion",
    visualEvolutionMemo: "落ち着いた成長が続いている。",
    lastGeneratedVideoUrl: "gs://demo-bucket/characters/test-user/videoHistory/previous.mp4",
    lastGeneratedSquareVideoUrl:
      "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
  };
  userProfile = {
    age: 28,
    characterGender: "non_binary",
    appearancePreset: "sky",
  };

  recentSummaries: StoredDailySummary[] = [
    {
      dateKey: "2026-03-16",
      title: "小さく前進した日",
      diaryBody: "今日はUI を整えた。\n明日も少し進められたらいいな。",
      mood: "前向き",
      doneThings: ["UI を整えた"],
      reflection: "形になってきた。",
      tomorrowNote: "明日も少し進める。",
    },
  ];

  recentMessages = [{ role: "user", text: "今日は UI を整えた" }];
  markedGenerating: Array<Record<string, unknown>> = [];
  markedVideoGenerating: Array<Record<string, unknown>> = [];
  savedImages: Array<Record<string, unknown>> = [];
  savedVideos: Array<Record<string, unknown>> = [];

  async getCharacterContext() {
    return this.character;
  }

  async getUserProfileContext() {
    return this.userProfile;
  }

  async listRecentDailySummaries() {
    return this.recentSummaries;
  }

  async markCharacterImageGenerating(params: Record<string, unknown>) {
    this.markedGenerating.push(params);
  }

  async markCharacterVideoGenerating(params: Record<string, unknown>) {
    this.markedVideoGenerating.push(params);
  }

  async saveCharacterImage(params: Record<string, unknown>) {
    this.savedImages.push(params);
  }

  async getMessagesForDateKey() {
    return this.recentMessages;
  }

  async saveCharacterVideo(params: Record<string, unknown>) {
    this.savedVideos.push(params);
  }
}

class FakeAiService {
  imagePromptCalls = 0;
  lastImagePromptParams: Record<string, unknown> | null = null;
  motionVideoCalls = 0;
  motionVideoInputs: Array<{ imageBytes: Buffer; mimeType: string }> = [];
  lastMotionPromptParams: Record<string, unknown> | null = null;

  async generateVisualEvolutionMemo() {
    return "表情に少し自信がにじみ、姿勢もわずかに伸びてきた。";
  }

  buildCharacterImagePrompt(params: Record<string, unknown>) {
    this.imagePromptCalls += 1;
    this.lastImagePromptParams = params;
    return `image-prompt-${this.imagePromptCalls}`;
  }

  async generateRoomSceneItems() {
    return ["ダンベル", "水筒"];
  }

  async generateCharacterImage(): Promise<{
    mimeType: string;
    imageBytes: Buffer<ArrayBufferLike>;
  }> {
    return {
      mimeType: "image/png",
      imageBytes: Buffer.from("image-bytes"),
    };
  }

  buildCharacterMotionPrompt(params: Record<string, unknown>) {
    this.lastMotionPromptParams = params;
    return "base-motion";
  }

  async generateCharacterMotionVideo(params: {
    imageBytes: Buffer;
    mimeType: string;
  }): Promise<{
    mimeType: string;
    uri?: string;
    videoBytes?: Buffer<ArrayBufferLike>;
  }> {
    this.motionVideoCalls += 1;
    this.motionVideoInputs.push({
      imageBytes: params.imageBytes,
      mimeType: params.mimeType,
    });
    return {
      mimeType: "video/mp4",
      uri: "gs://demo-bucket/characters/test-user/videoHistory/demo.mp4",
    };
  }

  generateDailySummary(params: { dateKey: string }) {
    return {
      dateKey: params.dateKey,
      title: "fallback",
      diaryBody: "今日は会話から補完した。\n明日はもう少し進められたらいいな。",
      mood: "静か",
      doneThings: ["会話から補完した"],
      reflection: "fallback reflection",
      tomorrowNote: "fallback tomorrow",
    };
  }
}

class FailingImageAiService extends FakeAiService {
  override async generateCharacterImage(): Promise<{
    mimeType: string;
    imageBytes: Buffer<ArrayBufferLike>;
  }> {
    throw new Error("generation failed");
  }
}

class FailingVideoAiService extends FakeAiService {
  override async generateCharacterMotionVideo(): Promise<{
    mimeType: string;
    uri?: string;
    videoBytes?: Buffer<ArrayBufferLike>;
  }> {
    throw new Error("video generation failed");
  }
}

class FakeImageStore {
  async save() {
    return "gs://demo-bucket/characters/test-user/imageHistory/demo.png";
  }

  async load() {
    return {
      bytes: Buffer.from("base-image"),
      mimeType: "image/png",
    };
  }
}

class FakeVideoStore {
  loadCalls = 0;

  buildOutputGcsUri() {
    return "gs://demo-bucket/characters/test-user/videoHistory";
  }

  async save(params: { generatedUri?: string; variant?: string }) {
    if (params.generatedUri) {
      return params.generatedUri;
    }
    if (params.variant === "square") {
      return "gs://demo-bucket/characters/test-user/videoHistory/demo-square.mp4";
    }
    return "gs://demo-bucket/characters/test-user/videoHistory/demo.mp4";
  }

  async load() {
    this.loadCalls += 1;
    return {
      bytes: Buffer.from("video-bytes"),
      mimeType: "video/mp4",
    };
  }
}

class FakeVideoProcessor {
  calls = 0;
  inputs: Array<{ videoBytes: Buffer; mimeType: string }> = [];

  async createSquareVariant(params: {
    videoBytes: Buffer<ArrayBufferLike>;
    mimeType: string;
  }): Promise<{
    videoBytes: Buffer<ArrayBufferLike>;
    mimeType: string;
    debugInfo?: unknown;
  }> {
    this.calls += 1;
    this.inputs.push({ videoBytes: params.videoBytes, mimeType: params.mimeType });
    return {
      videoBytes: Buffer.from("square-video-bytes"),
      mimeType: "video/mp4",
    };
  }
}

class FailingVideoProcessor extends FakeVideoProcessor {
  override async createSquareVariant(): Promise<{
    videoBytes: Buffer<ArrayBufferLike>;
    mimeType: string;
    debugInfo?: unknown;
  }> {
    throw new Error("square crop failed");
  }
}

const repository = new FakeRepository();
const aiService = new FakeAiService();
const videoStore = new FakeVideoStore();
const videoProcessor = new FakeVideoProcessor();
const service = new CharacterImageService(
  repository as never,
  aiService as never,
  new FakeImageStore(),
  videoStore,
  videoProcessor as never,
);

const created = await service.generateAndPersist({
  userId: "test-user",
  title: "更新した姿",
  optionalNote: "少し春っぽく",
  now: new Date("2026-03-18T09:00:00+09:00"),
});

assert.equal(created.imageUrl, "gs://demo-bucket/characters/test-user/imageHistory/demo.png");
assert.equal(repository.markedGenerating.length, 1);
assert.equal(repository.markedVideoGenerating.length, 1);
assert.equal(repository.savedImages.length, 1);
assert.equal(repository.savedVideos.length, 1);
assert.equal(created.latestVideoUrl, "gs://demo-bucket/characters/test-user/videoHistory/demo.mp4");
assert.equal(
  created.latestSquareVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/demo-square.mp4",
);
assert.equal(created.videoStatus, "ready");
assert.equal(aiService.motionVideoCalls, 1);
assert.equal(aiService.motionVideoInputs[0]?.mimeType, "image/png");
assert.equal(aiService.motionVideoInputs[0]?.imageBytes.toString(), "image-bytes");
assert.equal(aiService.lastImagePromptParams?.age, 28);
assert.equal(aiService.lastImagePromptParams?.characterGender, "non_binary");
assert.equal(aiService.lastImagePromptParams?.appearancePreset, "sky");
assert.equal(aiService.lastMotionPromptParams?.age, 28);
assert.equal(aiService.lastMotionPromptParams?.characterGender, "non_binary");
assert.equal(aiService.lastMotionPromptParams?.appearancePreset, "sky");
assert.equal(videoStore.loadCalls, 1);
assert.equal(videoProcessor.calls, 1);
assert.equal(videoProcessor.inputs[0]?.mimeType, "video/mp4");
assert.equal(videoProcessor.inputs[0]?.videoBytes.toString(), "video-bytes");

const failedRepository = new FakeRepository();
const failedService = new CharacterImageService(
  failedRepository as never,
  new FailingImageAiService() as never,
  new FakeImageStore(),
  new FakeVideoStore(),
  new FakeVideoProcessor() as never,
);

await assert.rejects(() =>
  failedService.generateAndPersist({
    userId: "test-user",
    title: "更新した姿",
    now: new Date("2026-03-18T09:00:00+09:00"),
  }),
);
assert.equal(failedRepository.savedImages.length, 0);

const failedVideoRepository = new FakeRepository();
const failedVideoService = new CharacterImageService(
  failedVideoRepository as never,
  new FailingVideoAiService() as never,
  new FakeImageStore(),
  new FakeVideoStore(),
  new FakeVideoProcessor() as never,
);

const failedVideoResult = await failedVideoService.generateAndPersist({
  userId: "test-user",
  title: "更新した姿",
  now: new Date("2026-03-18T09:00:00+09:00"),
});

assert.equal(failedVideoRepository.savedImages.length, 1);
assert.equal(failedVideoRepository.savedVideos.length, 1);
assert.equal(
  failedVideoResult.latestVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/previous.mp4",
);
assert.equal(
  failedVideoResult.latestSquareVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
);
assert.equal(failedVideoResult.videoStatus, "failed");

const cropFailureRepository = new FakeRepository();
const cropFailureService = new CharacterImageService(
  cropFailureRepository as never,
  new FakeAiService() as never,
  new FakeImageStore(),
  new FakeVideoStore(),
  new FailingVideoProcessor() as never,
);

const cropFailureResult = await cropFailureService.generateAndPersist({
  userId: "test-user",
  title: "更新した姿",
  now: new Date("2026-03-18T09:00:00+09:00"),
});

assert.equal(
  cropFailureResult.latestVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/demo.mp4",
);
assert.equal(
  cropFailureResult.latestSquareVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
);
assert.equal(cropFailureResult.videoStatus, "ready");

const candidates = parseCropdetectCandidates(`
[Parsed_cropdetect_0 @ 0x0000] x1:0 x2:1279 y1:0 y2:719 w:1280 h:720 x:0 y:0 pts:0 t:0.000000 crop=1280:720:0:0
[Parsed_cropdetect_0 @ 0x0000] x1:90 x2:1189 y1:0 y2:719 w:1100 h:720 x:90 y:0 pts:1 t:0.033333 crop=1100:720:90:0
`);
assert.deepEqual(candidates, [
  { width: 1280, height: 720, x: 0, y: 0 },
  { width: 1100, height: 720, x: 90, y: 0 },
]);

const detectedDebugInfo = resolveSquareVariantDebugInfo({
  inputWidth: 1280,
  inputHeight: 720,
  cropdetectOutput: `
[Parsed_cropdetect_0 @ 0x0000] crop=1040:720:120:0
[Parsed_cropdetect_0 @ 0x0000] crop=1100:720:90:0
`,
});
assert.equal(detectedDebugInfo.detection, "detected");
assert.deepEqual(detectedDebugInfo.contentRect, {
  width: 1100,
  height: 720,
  x: 90,
  y: 0,
});
assert.deepEqual(detectedDebugInfo.squareRect, {
  width: 720,
  height: 720,
  x: 280,
  y: 0,
});

const fullFrameDebugInfo = resolveSquareVariantDebugInfo({
  inputWidth: 1280,
  inputHeight: 720,
  cropdetectOutput: "",
});
assert.equal(fullFrameDebugInfo.detection, "full_frame");
assert.deepEqual(fullFrameDebugInfo.contentRect, {
  width: 1280,
  height: 720,
  x: 0,
  y: 0,
});
assert.deepEqual(fullFrameDebugInfo.squareRect, {
  width: 720,
  height: 720,
  x: 280,
  y: 0,
});

const unstableDebugInfo = resolveSquareVariantDebugInfo({
  inputWidth: 1280,
  inputHeight: 720,
  cropdetectOutput: `
[Parsed_cropdetect_0 @ 0x0000] crop=880:420:200:150
`,
});
assert.equal(unstableDebugInfo.detection, "unstable");
assert.deepEqual(unstableDebugInfo.contentRect, {
  width: 1280,
  height: 720,
  x: 0,
  y: 0,
});

assert.equal(buildAppDateKey(new Date("2026-03-17T02:59:00+09:00")), "2026-03-16");
assert.equal(buildAppDateKey(new Date("2026-03-17T03:00:00+09:00")), "2026-03-17");
assert.equal(buildAppDateKey(new Date("2026-03-17T17:59:00Z")), "2026-03-17");
assert.equal(buildAppDateKey(new Date("2026-03-17T18:00:00Z")), "2026-03-18");

const appDateWindow = buildAppDateWindow("2026-03-17");
assert.equal(appDateWindow.startAt.toISOString(), "2026-03-16T18:00:00.000Z");
assert.equal(appDateWindow.endAt.toISOString(), "2026-03-17T18:00:00.000Z");

const excerpt = buildPromptExcerpt({
  visualEvolutionMemo: "表情に少し自信がにじんでいる。",
  todaySummary: "日付: 2026-03-16\nやったこと: UI を整えた",
  sceneItems: ["ダンベル", "水筒"],
  optionalNote: "少し春っぽい",
});

assert.doesNotMatch(excerpt, /slot=/);
assert.match(excerpt, /growth=/);
assert.match(excerpt, /roomItems=ダンベル, 水筒/);

const motionExcerpt = buildMotionPromptExcerpt({
  visualEvolutionMemo: "表情に少し自信がにじんでいる。",
  todaySummary: "日付: 2026-03-16\nやったこと: UI を整えた",
  sceneItems: ["ダンベル", "水筒"],
  optionalNote: "少し春っぽい",
});

assert.doesNotMatch(motionExcerpt, /slot=/);
assert.match(motionExcerpt, /motionGrowth=/);
assert.match(motionExcerpt, /motionRoomItems=ダンベル, 水筒/);

console.log("character-image-service tests passed");

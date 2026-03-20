import assert from "node:assert/strict";
import {
  buildMotionPromptExcerpt,
  buildPromptExcerpt,
  CharacterImageService,
} from "./character-image-service.js";
import { buildAppDateKey, buildAppDateWindow } from "./app-date.js";
import { StoredDailySummary } from "../types.js";

class FakeRepository {
  character = {
    name: "Mori",
    visualPromptBase: "soft illustrated companion",
    visualEvolutionMemo: "落ち着いた成長が続いている。",
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
  motionVideoCalls = 0;
  motionVideoInputs: Array<{ imageBytes: Buffer; mimeType: string }> = [];

  async generateVisualEvolutionMemo() {
    return "表情に少し自信がにじみ、姿勢もわずかに伸びてきた。";
  }

  buildCharacterImagePrompt() {
    this.imagePromptCalls += 1;
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

  buildCharacterMotionPrompt() {
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
  buildOutputGcsUri() {
    return "gs://demo-bucket/characters/test-user/videoHistory";
  }

  async save(params: { generatedUri?: string }) {
    return params.generatedUri ?? "gs://demo-bucket/characters/test-user/videoHistory/demo.mp4";
  }
}

const repository = new FakeRepository();
const aiService = new FakeAiService();
const service = new CharacterImageService(
  repository as never,
  aiService as never,
  new FakeImageStore(),
  new FakeVideoStore(),
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
assert.equal(created.videoStatus, "ready");
assert.equal(aiService.motionVideoCalls, 1);
assert.equal(aiService.motionVideoInputs[0]?.mimeType, "image/png");
assert.equal(aiService.motionVideoInputs[0]?.imageBytes.toString(), "image-bytes");

const failedRepository = new FakeRepository();
const failedService = new CharacterImageService(
  failedRepository as never,
  new FailingImageAiService() as never,
  new FakeImageStore(),
  new FakeVideoStore(),
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
);

const failedVideoResult = await failedVideoService.generateAndPersist({
  userId: "test-user",
  title: "更新した姿",
  now: new Date("2026-03-18T09:00:00+09:00"),
});

assert.equal(failedVideoRepository.savedImages.length, 1);
assert.equal(failedVideoRepository.savedVideos.length, 1);
assert.equal(failedVideoResult.latestVideoUrl, null);
assert.equal(failedVideoResult.videoStatus, "failed");

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

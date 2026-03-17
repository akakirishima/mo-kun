import assert from "node:assert/strict";
import {
  buildPromptExcerpt,
  CharacterImageService,
} from "./character-image-service.js";
import { buildAppDateKey, buildAppDateWindow } from "./app-date.js";
import { StoredDailySummary } from "../types.js";

class FakeRepository {
  character = {
    name: "Mori",
    visualPromptBase: "soft illustrated companion",
  };

  recentSummaries: StoredDailySummary[] = [
    {
      dateKey: "2026-03-16",
      title: "小さく前進した日",
      mood: "前向き",
      doneThings: ["UI を整えた"],
      reflection: "形になってきた。",
      tomorrowNote: "明日も少し進める。",
    },
  ];

  recentMessages = [{ role: "user", text: "今日は UI を整えた" }];
  markedGenerating: Array<Record<string, unknown>> = [];
  savedImages: Array<{
    status: string;
    image: {
      imageUrl?: string | null;
      dateKey?: string;
    };
    dateKey?: string;
  }> = [];

  async getCharacterContext() {
    return this.character;
  }

  async listRecentDailySummaries() {
    return this.recentSummaries;
  }

  async markCharacterImageGenerating(params: Record<string, unknown>) {
    this.markedGenerating.push(params);
  }

  async saveCharacterImage(params: {
    status: string;
    image: {
      imageUrl?: string | null;
      dateKey?: string;
    };
    dateKey?: string;
  }) {
    this.savedImages.push(params);
  }

  async getMessagesForDateKey() {
    return this.recentMessages;
  }
}

class FakeAiService {
  generatedPrompt = "";
  generatedSceneItems: string[] = [];

  async generateVisualEvolutionMemo() {
    return "表情に少し自信がにじみ、姿勢もわずかに伸びてきた。";
  }

  buildCharacterImagePrompt(params: {
    visualEvolutionMemo: string;
    todaySummary: string;
    sceneItems: string[];
    optionalNote?: string;
  }) {
    this.generatedSceneItems = params.sceneItems;
    this.generatedPrompt = [
      params.visualEvolutionMemo,
      params.todaySummary,
      params.sceneItems.join(", "),
      params.optionalNote ?? "",
    ].join("\n");
    return this.generatedPrompt;
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

  generateDailySummary(params: { dateKey: string }) {
    return {
      dateKey: params.dateKey,
      title: "fallback",
      mood: "静か",
      doneThings: ["会話から補完した"],
      reflection: "fallback reflection",
      tomorrowNote: "fallback tomorrow",
    };
  }
}

class FailingAiService extends FakeAiService {
  override async generateCharacterImage(): Promise<{
    mimeType: string;
    imageBytes: Buffer<ArrayBufferLike>;
  }> {
    throw new Error("generation failed");
  }
}

class FakeImageStore {
  async save() {
    return "gs://demo-bucket/characters/test-user/imageHistory/demo.png";
  }
}

const repository = new FakeRepository();
const aiService = new FakeAiService();
const service = new CharacterImageService(
  repository as never,
  aiService as never,
  new FakeImageStore(),
);

const created = await service.generateAndPersist({
  userId: "test-user",
  title: "更新した姿",
  optionalNote: "少し春っぽく",
});

assert.equal(
  created.imageUrl,
  "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
);
assert.equal(repository.markedGenerating.length, 1);
assert.equal(repository.savedImages.length, 1);
assert.equal(repository.savedImages[0].status, "ready");
assert.equal(repository.savedImages[0].dateKey, buildAppDateKey(new Date()));
assert.match(aiService.generatedPrompt, /表情に少し自信/);
assert.match(aiService.generatedPrompt, /小さく前進した日|日付:/);
assert.deepEqual(aiService.generatedSceneItems, ["ダンベル", "水筒"]);
assert.match(aiService.generatedPrompt, /少し春っぽく/);

const failedRepository = new FakeRepository();
const failedService = new CharacterImageService(
  failedRepository as never,
  new FailingAiService() as never,
  new FakeImageStore(),
);

await assert.rejects(() =>
  failedService.generateAndPersist({
    userId: "test-user",
    title: "更新した姿",
  }),
);
assert.equal(failedRepository.savedImages.length, 1);
assert.equal(failedRepository.savedImages[0].status, "failed");
assert.equal(failedRepository.savedImages[0].image.imageUrl, null);
assert.equal(failedRepository.savedImages[0].dateKey, buildAppDateKey(new Date()));

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

assert.match(excerpt, /growth=/);
assert.match(excerpt, /today=/);
assert.match(excerpt, /roomItems=ダンベル, 水筒/);
assert.match(excerpt, /note=/);

console.log("character-image-service tests passed");

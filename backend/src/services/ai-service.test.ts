import assert from "node:assert/strict";
import {
  buildAssistantPrompt,
  buildAssistantSystemInstruction,
  buildCharacterImagePrompt,
  buildVisualEvolutionPrompt,
  extractGeneratedImage,
  normalizeAssistantReply,
} from "./ai-service.js";

const prompt = buildAssistantPrompt(
  [
    { role: "assistant", text: "まずは深呼吸しよう" },
    { role: "user", text: "今日は筋トレした" },
    { role: "system", text: "ignored" },
  ],
  "夜はストレッチもした",
);

assert.match(prompt, /パートナー: まずは深呼吸しよう/);
assert.match(prompt, /ユーザー: 今日は筋トレした/);
assert.match(prompt, /今回のユーザー入力: 夜はストレッチもした/);

const instruction = buildAssistantSystemInstruction(
  "Mori",
  "ユーザーに寄り添い、やわらかい口調で話す。",
);

assert.match(instruction, /Mori/);
assert.match(instruction, /やわらかい口調/);
assert.match(instruction, /2〜5文程度/);
assert.match(instruction, /自然にねぎらってよい/);
assert.match(instruction, /引用しすぎない/);

assert.equal(normalizeAssistantReply(" こんにちは\n"), "こんにちは。");
assert.equal(normalizeAssistantReply("   \n  "), null);
assert.equal(
  normalizeAssistantReply("そうか、頑張ったんだな。次も少しずつ続けようよ"),
  "そうか、頑張ったんだな。次も少しずつ続けようよ。",
);
assert.equal(
  normalizeAssistantReply("「なに？」だと？筋トレも開発も、両方"),
  "「なに？」だと？筋トレも開発も、両方。",
);

const visualPrompt = buildVisualEvolutionPrompt([
  {
    dateKey: "2026-03-16",
    title: "小さく前進した日",
    mood: "前向き",
    doneThings: ["UI を整えた", "報告を 1 つ送った"],
    reflection: "少しずつ形になった。",
    tomorrowNote: "朝に短く報告する。",
  },
]);

assert.match(visualPrompt, /直近7日分/);
assert.match(visualPrompt, /UI を整えた/);
assert.match(visualPrompt, /朝に短く報告する/);

const imagePrompt = buildCharacterImagePrompt({
  characterName: "Mori",
  visualPromptBase: "soft illustrated companion",
  visualEvolutionMemo: "表情に少し自信が出てきた。",
  todaySummary: "日付: 2026-03-16\nやったこと: UI を整えた",
  optionalNote: "少し春っぽい空気感",
});

assert.match(imagePrompt, /soft illustrated companion/);
assert.match(imagePrompt, /表情に少し自信が出てきた/);
assert.match(imagePrompt, /少し春っぽい空気感/);
assert.match(imagePrompt, /連続性ルール/);
assert.match(imagePrompt, /トロフィーや数値のような露骨な記号化は避ける/);

const generatedImage = extractGeneratedImage({
  candidates: [
    {
      content: {
        parts: [
          { text: "generated" },
          {
            inlineData: {
              mimeType: "image/png",
              data: Buffer.from("fake-image").toString("base64"),
            },
          },
        ],
      },
    },
  ],
});

assert.equal(generatedImage.mimeType, "image/png");
assert.equal(generatedImage.imageBytes.toString("utf8"), "fake-image");

console.log("ai-service tests passed");

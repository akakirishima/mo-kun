import assert from "node:assert/strict";
import {
  buildAssistantPrompt,
  buildAssistantSystemInstruction,
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

console.log("ai-service tests passed");

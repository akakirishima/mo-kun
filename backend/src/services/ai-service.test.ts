import assert from "node:assert/strict";
import {
  buildAssistantPrompt,
  buildAssistantSystemInstruction,
  buildCharacterImagePrompt,
  buildDailySummaryPrompt,
  buildDailySummarySystemInstruction,
  buildFallbackDailySummary,
  buildRoomSceneItemsPrompt,
  buildRoomSceneItemsSystemInstruction,
  buildVisualEvolutionPrompt,
  extractGeneratedImage,
  normalizeAssistantReply,
  normalizeGeneratedDailySummary,
  normalizeGeneratedRoomSceneItems,
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

const dailySummaryInstruction = buildDailySummarySystemInstruction();
assert.match(dailySummaryInstruction, /日次ダイアリー用/);
assert.match(dailySummaryInstruction, /JSON 以外を返さない/);
assert.match(dailySummaryInstruction, /diaryBody/);

const dailySummaryPrompt = buildDailySummaryPrompt({
  dateKey: "2026-03-16",
  messages: [
    { role: "assistant", text: "まずは落ち着いて整理しよう" },
    { role: "user", text: "今日は UI を整えて、報告も 1 つ送った" },
  ],
});
assert.match(dailySummaryPrompt, /対象日: 2026-03-16/);
assert.match(dailySummaryPrompt, /assistant: まずは落ち着いて整理しよう/);
assert.match(dailySummaryPrompt, /user: 今日は UI を整えて、報告も 1 つ送った/);
assert.match(dailySummaryPrompt, /doneThings/);
assert.match(dailySummaryPrompt, /diaryBody/);

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

const fallbackDailySummary = buildFallbackDailySummary({
  dateKey: "2026-03-16",
  messages: [
    { role: "assistant", text: "今日はどうだった？" },
    { role: "user", text: "朝に報告を 1 つ送った" },
    { role: "user", text: "夜は UI の余白も整えた" },
  ],
});

assert.equal(fallbackDailySummary.dateKey, "2026-03-16");
assert.equal(fallbackDailySummary.doneThings.length, 2);
assert.match(fallbackDailySummary.diaryBody, /今日は/);
assert.match(fallbackDailySummary.diaryBody, /明日は/);
assert.match(fallbackDailySummary.reflection, /UI の余白も整えた/);

const normalizedDailySummary = normalizeGeneratedDailySummary({
  dateKey: "2026-03-16",
  rawText: `\`\`\`json
{"title":"積み上げを整えた日","mood":"前向き","doneThings":["報告を 1 つ送った","UI の余白を整えた"],"reflection":"やったことを言葉にしたことで、進み方が見えやすくなった。","tomorrowNote":"明日も短く進捗を残す。"}
\`\`\``,
  fallback: fallbackDailySummary,
});

const normalizedDailySummaryWithDiaryBody = normalizeGeneratedDailySummary({
  dateKey: "2026-03-16",
  rawText: `\`\`\`json
{"title":"積み上げを整えた日","diaryBody":"今日は報告を 1 つ送って、UI の余白も整えた。\\n明日は短く進捗を残せたらいいな。","mood":"前向き","doneThings":["報告を 1 つ送った","UI の余白を整えた"],"reflection":"やったことを言葉にしたことで、進み方が見えやすくなった。","tomorrowNote":"明日も短く進捗を残す。"}
\`\`\``,
  fallback: fallbackDailySummary,
});

assert.equal(normalizedDailySummary?.dateKey, "2026-03-16");
assert.equal(normalizedDailySummary?.title, "積み上げを整えた日");
assert.equal(normalizedDailySummary?.diaryBody, fallbackDailySummary.diaryBody);
assert.equal(
  normalizedDailySummaryWithDiaryBody?.diaryBody,
  "今日は報告を 1 つ送って、UI の余白も整えた。\n明日は短く進捗を残せたらいいな。",
);
assert.deepEqual(normalizedDailySummary?.doneThings, [
  "報告を 1 つ送った",
  "UI の余白を整えた",
]);

const visualPrompt = buildVisualEvolutionPrompt([
  {
    dateKey: "2026-03-16",
    title: "小さく前進した日",
    diaryBody: "今日はUI を整えて、報告を 1 つ送った。\n明日は朝に短く報告できたらいいな。",
    mood: "前向き",
    doneThings: ["UI を整えた", "報告を 1 つ送った"],
    reflection: "少しずつ形になった。",
    tomorrowNote: "朝に短く報告する。",
  },
]);

assert.match(visualPrompt, /直近7日分/);
assert.match(visualPrompt, /UI を整えた/);
assert.match(visualPrompt, /朝に短く報告する/);

const roomSceneInstruction = buildRoomSceneItemsSystemInstruction();
assert.match(roomSceneInstruction, /部屋の中に置ける具体物/);
assert.match(roomSceneInstruction, /0〜4 件/);

const roomScenePrompt = buildRoomSceneItemsPrompt({
  todaySummary: "日付: 2026-03-16\nやったこと: 筋トレ / ゲーム",
  messages: [
    { role: "user", text: "今日は筋トレして、そのあとゲームした" },
    { role: "assistant", text: "いい流れだね" },
  ],
  optionalNote: "かわいい部屋",
});
assert.match(roomScenePrompt, /筋トレ/);
assert.match(roomScenePrompt, /ゲームした/);
assert.doesNotMatch(roomScenePrompt, /assistant: いい流れだね/);

const normalizedSceneItems = normalizeGeneratedRoomSceneItems(
  '{"items":["ダンベル","ゲームコントローラー","雰囲気","ダンベル","水筒"]}',
);
assert.deepEqual(normalizedSceneItems, [
  "ダンベル",
  "ゲームコントローラー",
  "水筒",
]);

const imagePrompt = buildCharacterImagePrompt({
  characterName: "Mori",
  visualPromptBase: "soft illustrated companion",
  visualEvolutionMemo: "表情に少し自信が出てきた。",
  todaySummary: "日付: 2026-03-16\nやったこと: UI を整えた",
  sceneItems: ["ノートPC", "付せんメモ"],
  optionalNote: "少し春っぽい空気感",
});

assert.match(imagePrompt, /pixel-art isometric room illustration/);
assert.match(imagePrompt, /wide horizontal composition/);
assert.match(imagePrompt, /character stands or sits near the center/);
assert.match(imagePrompt, /desk top item: ノートPC/);
assert.match(imagePrompt, /表情に少し自信が出てきた/);
assert.match(imagePrompt, /少し春っぽい空気感/);
assert.match(imagePrompt, /構図ルール/);
assert.match(imagePrompt, /縦長の人物ポートレートにしない/);

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

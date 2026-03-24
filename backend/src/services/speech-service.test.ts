import assert from "node:assert/strict";
import { SpeechService } from "./speech-service.js";
import type { AppConfig } from "../config.js";

const config: AppConfig = {
  projectId: "test-project",
  vertexLocation: "global",
  geminiModel: "gemini-2.5-pro",
  geminiImageModel: "gemini-2.5-flash-image",
  veoModel: "veo-3.1-generate-001",
  geminiTemperature: 0.5,
  geminiMaxOutputTokens: 480,
  geminiThinkingBudget: 128,
  imageBucket: "test-bucket",
  speechLanguageCode: "ja-JP",
  ttsLanguageCode: "ja-JP",
  ttsModelName: "gemini-2.5-flash-tts",
  ttsVoiceName: "Kore",
  ttsPrompt: "should not be passed to tts input",
  ttsAudioEncoding: "MP3",
  dailyRefreshSecret: "secret",
  port: 8080,
};

const service = new SpeechService(config);

let capturedRequest: unknown;
(service as unknown as {
  textToSpeechClient: {
    synthesizeSpeech: (request: unknown) => Promise<Array<{ audioContent: Uint8Array }>>;
  };
}).textToSpeechClient = {
  async synthesizeSpeech(request: unknown) {
    capturedRequest = request;
    return [{ audioContent: Uint8Array.from([1, 2, 3]) }];
  },
};

const synthesized = await service.synthesizeAssistantSpeech({
  text: "  今日は\nよく頑張ったね  ",
});

assert.equal(synthesized.mimeType, "audio/mpeg");
assert.deepEqual([...synthesized.audioBytes], [1, 2, 3]);
assert.deepEqual(capturedRequest, {
  input: {
    text: "今日は よく頑張ったね",
  },
  voice: {
    languageCode: "ja-JP",
    name: "Kore",
    modelName: "gemini-2.5-flash-tts",
  },
  audioConfig: {
    audioEncoding: "MP3",
    speakingRate: 1,
    pitch: 0,
    sampleRateHertz: 24000,
  },
});

console.log("speech-service tests passed");

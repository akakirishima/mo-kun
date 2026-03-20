export type AppConfig = {
  projectId: string;
  vertexLocation: string;
  geminiModel: string;
  geminiImageModel: string;
  veoModel: string;
  geminiTemperature: number;
  geminiMaxOutputTokens: number;
  imageBucket: string;
  speechLanguageCode: string;
  ttsLanguageCode: string;
  ttsModelName: string;
  ttsVoiceName: string;
  ttsPrompt: string;
  ttsAudioEncoding: "MP3";
  dailyRefreshSecret: string;
  port: number;
};

export function loadConfig(): AppConfig {
  return {
    projectId: process.env.GOOGLE_CLOUD_PROJECT ?? 'local-project',
    vertexLocation: process.env.VERTEX_LOCATION ?? 'global',
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.5-pro',
    geminiImageModel:
      process.env.GEMINI_IMAGE_MODEL ?? 'gemini-2.5-flash-image',
    veoModel: process.env.VEO_MODEL ?? 'veo-3.1-generate-001',
    geminiTemperature: Number(process.env.GEMINI_TEMPERATURE ?? 0.5),
    geminiMaxOutputTokens: Number(process.env.GEMINI_MAX_OUTPUT_TOKENS ?? 480),
    imageBucket: process.env.IMAGE_BUCKET ?? 'local-bucket',
    speechLanguageCode: process.env.SPEECH_LANGUAGE_CODE ?? 'ja-JP',
    ttsLanguageCode: process.env.TTS_LANGUAGE_CODE ?? 'ja-JP',
    ttsModelName: process.env.TTS_MODEL_NAME ?? 'gemini-2.5-flash-tts',
    ttsVoiceName: process.env.TTS_VOICE_NAME ?? 'Kore',
    ttsPrompt:
      process.env.TTS_PROMPT ??
      '落ち着いた日本語で、やわらかく自然に話す。内なる声として近すぎず遠すぎない距離感で、過度な抑揚を避ける。',
    ttsAudioEncoding: 'MP3',
    dailyRefreshSecret: process.env.DAILY_REFRESH_SECRET ?? 'local-secret',
    port: Number(process.env.PORT ?? 8080),
  };
}

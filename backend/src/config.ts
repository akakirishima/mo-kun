export type AppConfig = {
  projectId: string;
  vertexLocation: string;
  liveVertexLocation: string;
  geminiModel: string;
  geminiImageModel: string;
  veoModel: string;
  livePrimaryModel: string;
  liveFallbackModel: string;
  liveSessionHandleTtlSeconds: number;
  geminiTemperature: number;
  geminiMaxOutputTokens: number;
  geminiThinkingBudget: number;
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
    liveVertexLocation:
      process.env.LIVE_VERTEX_LOCATION ?? process.env.VERTEX_LOCATION ?? 'us-central1',
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.5-pro',
    geminiImageModel:
      process.env.GEMINI_IMAGE_MODEL ?? 'gemini-2.5-flash-image',
    veoModel: process.env.VEO_MODEL ?? 'veo-3.1-generate-001',
    livePrimaryModel:
      process.env.LIVE_MODEL_PRIMARY ?? 'gemini-live-2.5-flash-native-audio',
    liveFallbackModel:
      process.env.LIVE_MODEL_FALLBACK ??
      process.env.LIVE_MODEL_PRIMARY ??
      'gemini-live-2.5-flash-native-audio',
    liveSessionHandleTtlSeconds: Number(
      process.env.LIVE_SESSION_HANDLE_TTL_SECONDS ?? 1800,
    ),
    geminiTemperature: Number(process.env.GEMINI_TEMPERATURE ?? 0.5),
    geminiMaxOutputTokens: Number(process.env.GEMINI_MAX_OUTPUT_TOKENS ?? 2048),
    geminiThinkingBudget: Number(process.env.GEMINI_THINKING_BUDGET ?? 128),
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

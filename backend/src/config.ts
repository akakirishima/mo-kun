export type AppConfig = {
  projectId: string;
  vertexLocation: string;
  geminiModel: string;
  geminiImageModel: string;
  geminiTemperature: number;
  geminiMaxOutputTokens: number;
  imageBucket: string;
  dailyRefreshSecret: string;
  port: number;
};

export function loadConfig(): AppConfig {
  return {
    projectId: process.env.GOOGLE_CLOUD_PROJECT ?? 'local-project',
    vertexLocation: process.env.VERTEX_LOCATION ?? 'global',
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.5-flash',
    geminiImageModel:
      process.env.GEMINI_IMAGE_MODEL ?? 'gemini-2.5-flash-image',
    geminiTemperature: Number(process.env.GEMINI_TEMPERATURE ?? 0.5),
    geminiMaxOutputTokens: Number(process.env.GEMINI_MAX_OUTPUT_TOKENS ?? 320),
    imageBucket: process.env.IMAGE_BUCKET ?? 'local-bucket',
    dailyRefreshSecret: process.env.DAILY_REFRESH_SECRET ?? 'local-secret',
    port: Number(process.env.PORT ?? 8080),
  };
}

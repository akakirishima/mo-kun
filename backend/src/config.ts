export type AppConfig = {
  projectId: string;
  vertexLocation: string;
  geminiModel: string;
  imageModel: string;
  dailyRefreshSecret: string;
  port: number;
};

export function loadConfig(): AppConfig {
  return {
    projectId: process.env.GOOGLE_CLOUD_PROJECT ?? 'local-project',
    vertexLocation: process.env.VERTEX_LOCATION ?? 'asia-northeast1',
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.0-flash',
    imageModel: process.env.IMAGE_MODEL ?? 'imagen',
    dailyRefreshSecret: process.env.DAILY_REFRESH_SECRET ?? 'local-secret',
    port: Number(process.env.PORT ?? 8080),
  };
}

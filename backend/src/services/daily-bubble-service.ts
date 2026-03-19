import { AppRepository } from "../repositories/app-repository.js";
import { AiService } from "./ai-service.js";
import { buildAppDateKey, previousAppDateKey } from "./app-date.js";
import { StoredDailyBubble } from "../types.js";

export class DailyBubbleService {
  constructor(
    private readonly repository: AppRepository,
    private readonly aiService: AiService,
  ) {}

  async ensureTodayBubble(params: {
    userId: string;
    now?: Date;
  }): Promise<StoredDailyBubble> {
    const now = params.now ?? new Date();
    const dateKey = buildAppDateKey(now);
    const existing = await this.repository.getDailyBubble(params.userId, dateKey);
    if (existing) {
      return existing;
    }

    const sourceDateKey = previousAppDateKey(dateKey);
    const previousSummary = await this.repository.getDailySummary(
      params.userId,
      sourceDateKey,
    );
    const bubble = await this.aiService.generateDailyBubble({
      dateKey,
      previousSummary: previousSummary ?? undefined,
    });
    await this.repository.saveDailyBubble(params.userId, bubble);

    return {
      ...bubble,
      generatedAt: now.toISOString(),
    };
  }
}

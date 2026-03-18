import { AppRepository } from "../repositories/app-repository.js";
import { ChatService } from "./chat-service.js";
import { ImageService } from "./image-service.js";

export class DailyRefreshService {
  constructor(
    private readonly repository: AppRepository,
    private readonly chatService: ChatService,
    private readonly imageService: ImageService,
  ) {}

  async refreshAllUsers() {
    const userIds = await this.repository.listUsersForRefresh();
    let processed = 0;

    for (const userId of userIds) {
      const character = await this.repository.getCharacterContext(userId);
      if (!character) {
        continue;
      }

      const threadId = `${userId}_main`;
      const messages = await this.repository.getRecentMessages(threadId, 20);
      const recentUserTexts = messages
        .filter((message) => message.role === "user")
        .map((message) => String(message.text ?? ""));

      if (recentUserTexts.length === 0) {
        continue;
      }

      const summaryText = recentUserTexts.slice(-3).join(" / ");
      const dateKey = this.dateKey(new Date());
      await this.repository.saveDailySummary(userId, {
        dateKey,
        title: "会話からまとめた一日",
        diaryBody: `今日は${recentUserTexts.slice(-2).join("、")}。\n明日はもう少し続きを進められたらいいな。`,
        mood: "前進中",
        doneThings: recentUserTexts.slice(-3),
        reflection: await this.chatService.reply({
          userText: summaryText,
          personaPrompt: String(character.personaPrompt ?? ""),
          recentMessages: messages,
        }),
        tomorrowNote: "朝に一言だけでも報告して流れをつなげる。",
      });

      const image = await this.imageService.generate({
        userId,
        characterName: String(character.name ?? "Mori"),
        visualPromptBase: String(character.visualPromptBase ?? ""),
        reportText: summaryText,
      });
      await this.repository.saveCharacterImage({ userId, image });
      processed += 1;
    }

    return { processed };
  }

  private dateKey(date: Date) {
    const adjusted = date.getHours() < 3
      ? new Date(date.getTime() - 24 * 60 * 60 * 1000)
      : date;
    const year = adjusted.getFullYear();
    const month = String(adjusted.getMonth() + 1).padStart(2, "0");
    const day = String(adjusted.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }
}


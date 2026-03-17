import { CharacterDraft, DailySummaryDraft, ImageDraft } from "../types.js";

type CharacterProfileInput = {
  displayName: string;
  goal: string;
  partnerStyle: string;
  weakPoints: string[];
};

type MessageContext = Array<{ role?: string; text?: string }>;

export class AiService {
  generateCharacterDraft(profile: CharacterProfileInput): CharacterDraft {
    const weakPoints =
      profile.weakPoints.length === 0
        ? "継続が途切れないように見守る"
        : `特に ${profile.weakPoints.join("、")} を気にかける`;

    return {
      name: `${profile.displayName || "Mori"}の相棒`,
      personaPrompt: [
        "あなたはユーザーの分身に近いAIパートナーです。",
        `ユーザーの目標: ${profile.goal}`,
        `接し方: ${profile.partnerStyle}`,
        `注意点: ${weakPoints}`,
      ].join("\n"),
      visualPromptBase: [
        "soft illustrated companion",
        `goal: ${profile.goal}`,
        `tone: ${profile.partnerStyle}`,
      ].join(", "),
      starterGreeting: `${profile.displayName || "きみ"}、今日から一緒に進もう。まずは今日のことを聞かせて。`,
    };
  }

  generateAssistantReply(params: {
    characterName: string;
    recentMessages: MessageContext;
    userText: string;
  }): string {
    const recentUserText =
      params.recentMessages
        .filter((message) => message.role === "user" && !!message.text)
        .map((message) => message.text)
        .slice(0, 2)
        .join(" / ") || "まだ会話は始まったばかり";

    return [
      `${params.characterName}として受け取ったよ。`,
      `今の報告: ${params.userText}`,
      `直近の流れ: ${recentUserText}`,
      "明日の見た目や日記にもつながるように覚えておくね。",
    ].join(" ");
  }

  generateImageDraft(params: {
    title: string;
    visualPromptBase: string;
    reportText: string;
    userId: string;
  }): ImageDraft {
    const slug = Date.now().toString();
    return {
      title: params.title,
      promptExcerpt: `${params.visualPromptBase} / ${params.reportText}`.trim(),
      imageUrl: `https://example.com/generated/${params.userId}/${slug}.png`,
    };
  }

  generateDailySummary(params: {
    dateKey: string;
    messages: MessageContext;
  }): DailySummaryDraft {
    const userMessages = params.messages
      .filter((message) => message.role === "user" && !!message.text)
      .map((message) => message.text!.trim())
      .filter((text) => text.length > 0);
    const doneThings = userMessages.slice(0, 3);
    const lead = doneThings.length === 0 ? "まだ報告がありません" : doneThings[0];

    return {
      dateKey: params.dateKey,
      title: "AIがまとめた今日の記録",
      mood: doneThings.length === 0 ? "静か" : "前向き",
      doneThings,
      reflection: `今日の流れは「${lead}」を中心に整理された。`,
      tomorrowNote: "明日は一言だけでも進捗を送って流れを続ける。",
    };
  }
}

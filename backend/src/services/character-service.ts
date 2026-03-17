import { CharacterDraft } from "../types.js";

export class CharacterService {
  async createDraft(input: {
    displayName: string;
    goal: string;
    partnerStyle: string;
    weakPoints: string[];
  }): Promise<CharacterDraft> {
    const weakPoints = input.weakPoints.length > 0
      ? `苦手: ${input.weakPoints.join(" / ")}`
      : "苦手: 未設定";

    return {
      name: "Mori",
      personaPrompt: [
        `あなたは${input.displayName}の分身キャラクターです。`,
        `${input.partnerStyle}で話してください。`,
        `目標は${input.goal}です。`,
        weakPoints,
      ].join("\n"),
      visualPromptBase: [
        `${input.displayName}の分身キャラクター`,
        `${input.goal}に向かう途中`,
        "やわらかいアニメ調",
      ].join(", "),
      starterGreeting: `${input.displayName}、今日から一緒に${input.goal}へ向かおう。`,
    };
  }
}


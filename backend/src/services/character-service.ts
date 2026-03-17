import { CharacterDraft } from "../types.js";
import { DEFAULT_ROOM_VISUAL_PROMPT_BASE } from "./ai-service.js";

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
        DEFAULT_ROOM_VISUAL_PROMPT_BASE,
        input.goal ? `goal mood hint: ${input.goal}` : null,
        input.partnerStyle ? `companion tone hint: ${input.partnerStyle}` : null,
      ].filter((value): value is string => value != null && value.length > 0).join(", "),
      starterGreeting: `${input.displayName}、今日から一緒に${input.goal}へ向かおう。`,
    };
  }
}


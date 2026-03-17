import { ImageDraft } from "../types.js";

export class ImageService {
  async generate(params: {
    userId: string;
    characterName: string;
    visualPromptBase: string;
    reportText: string;
  }): Promise<ImageDraft> {
    const excerpt = `${params.visualPromptBase} / ${params.reportText}`;
    return {
      title: "前日の報告を反映した姿",
      promptExcerpt: excerpt,
      imageUrl: `gs://demo-generated/${params.userId}/${Date.now()}.png`,
    };
  }
}


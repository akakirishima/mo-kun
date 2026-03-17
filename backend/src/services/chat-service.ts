export class ChatService {
  async reply(params: {
    userText: string;
    personaPrompt: string;
    recentMessages: Array<Record<string, unknown>>;
  }) {
    const message = params.userText;
    if (message.includes("筋トレ")) {
      return "筋トレ報告ありがとう。明日の姿に、少しだけ強さが見えるよう反映しておくね。";
    }
    if (message.includes("勉強") || message.includes("作業")) {
      return "集中した時間がちゃんと積み上がってる。次の姿にもその輪郭を残しておくよ。";
    }
    return "受け取ったよ。今日の報告は覚えておいて、明日の変化につなげるね。";
  }
}


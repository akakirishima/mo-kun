import speech from "@google-cloud/speech";
import textToSpeech from "@google-cloud/text-to-speech";
import { AppConfig, loadConfig } from "../config.js";

export class SpeechServiceError extends Error {
  constructor(message: string, cause?: unknown) {
    super(message, { cause });
    this.name = "SpeechServiceError";
  }
}

export type SynthesizedSpeech = {
  audioBytes: Buffer;
  mimeType: string;
};

export class SpeechService {
  private readonly speechClient = new speech.v1.SpeechClient();
  private readonly textToSpeechClient = new textToSpeech.v1.TextToSpeechClient();

  constructor(private readonly config: AppConfig = loadConfig()) {}

  async transcribeShortWav(params: {
    audioBytes: Buffer;
  }): Promise<string> {
    try {
      const [response] = await this.speechClient.recognize({
        config: {
          encoding: "LINEAR16",
          sampleRateHertz: 16000,
          languageCode: this.config.speechLanguageCode,
          model: "latest_short",
          enableAutomaticPunctuation: true,
        },
        audio: {
          content: params.audioBytes.toString("base64"),
        },
      });
      const transcript = response.results
        ?.flatMap((result) => result.alternatives ?? [])
        .map((alternative) => alternative.transcript?.trim())
        .filter((value): value is string => !!value && value.length > 0)
        .join(" ")
        .trim();

      if (!transcript) {
        throw new SpeechServiceError("speech_transcript_empty");
      }

      return transcript;
    } catch (error) {
      if (error instanceof SpeechServiceError) {
        throw error;
      }
      throw new SpeechServiceError("speech_transcription_failed", error);
    }
  }

  async synthesizeAssistantSpeech(params: {
    text: string;
    voiceName?: string;
  }): Promise<SynthesizedSpeech> {
    try {
      const [response] = await this.textToSpeechClient.synthesizeSpeech({
        input: {
          text: normalizeTtsText(params.text),
        },
        voice: {
          languageCode: this.config.ttsLanguageCode,
          name: params.voiceName ?? this.config.ttsVoiceName,
          modelName: this.config.ttsModelName,
        },
        audioConfig: {
          audioEncoding: this.config.ttsAudioEncoding,
          speakingRate: 1.0,
          pitch: 0.0,
          sampleRateHertz: 24000,
        },
      });

      const audioContent = response.audioContent;
      if (!audioContent) {
        throw new SpeechServiceError("tts_audio_missing");
      }

      const audioBytes = Buffer.isBuffer(audioContent)
        ? audioContent
        : Buffer.from(audioContent as Uint8Array);

      return {
        audioBytes,
        mimeType: "audio/mpeg",
      };
    } catch (error) {
      if (error instanceof SpeechServiceError) {
        throw error;
      }
      throw new SpeechServiceError("tts_synthesize_failed", error);
    }
  }
}

function normalizeTtsText(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length <= 320
    ? normalized
    : `${normalized.slice(0, 317).trimEnd()}...`;
}

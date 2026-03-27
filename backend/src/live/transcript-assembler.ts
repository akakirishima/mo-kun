import { Transcription } from "@google/genai";
import { randomUUID } from "node:crypto";

export type TranscriptEvent =
  | { kind: "input_partial"; turnId: string; text: string }
  | { kind: "input_final"; turnId: string; text: string }
  | { kind: "output_partial"; turnId: string; text: string }
  | { kind: "output_final"; turnId: string; text: string };

type TranscriptState = {
  partialText: string;
  finalText: string;
};

export class TranscriptAssembler {
  private currentTurnId = randomUUID();
  private inputState: TranscriptState = createTranscriptState();
  private outputState: TranscriptState = createTranscriptState();

  nextInput(transcription?: Transcription): TranscriptEvent[] {
    return this.apply("input", transcription);
  }

  nextOutput(transcription?: Transcription): TranscriptEvent[] {
    return this.apply("output", transcription);
  }

  currentFinalTexts() {
    return {
      turnId: this.currentTurnId,
      inputText: this.inputState.finalText.trim(),
      outputText: this.outputState.finalText.trim(),
    };
  }

  beginNextTurn() {
    this.currentTurnId = randomUUID();
    this.inputState = createTranscriptState();
    this.outputState = createTranscriptState();
  }

  private apply(
    kind: "input" | "output",
    transcription?: Transcription,
  ): TranscriptEvent[] {
    if (!transcription?.text?.trim()) {
      return [];
    }

    const state = kind === "input" ? this.inputState : this.outputState;
    const text = transcription.text.trim();
    if (transcription.finished) {
      state.finalText = text;
      state.partialText = text;
      return [
        {
          kind: kind === "input" ? "input_final" : "output_final",
          turnId: this.currentTurnId,
          text,
        },
      ];
    }

    state.partialText = text;
    return [
      {
        kind: kind === "input" ? "input_partial" : "output_partial",
        turnId: this.currentTurnId,
        text,
      },
    ];
  }
}

function createTranscriptState(): TranscriptState {
  return {
    partialText: "",
    finalText: "",
  };
}

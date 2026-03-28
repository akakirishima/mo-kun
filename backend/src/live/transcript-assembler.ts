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

  currentResolvedTexts() {
    return {
      turnId: this.currentTurnId,
      inputText: resolveTranscriptText(this.inputState),
      outputText: resolveTranscriptText(this.outputState),
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
    const mergedText = mergeTranscriptText(
      resolveTranscriptText(state),
      text,
      transcription.finished === true,
    );
    if (transcription.finished) {
      state.finalText = mergedText;
      state.partialText = mergedText;
      return [
        {
          kind: kind === "input" ? "input_final" : "output_final",
          turnId: this.currentTurnId,
          text: mergedText,
        },
      ];
    }

    state.partialText = mergedText;
    return [
      {
        kind: kind === "input" ? "input_partial" : "output_partial",
        turnId: this.currentTurnId,
        text: mergedText,
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

function resolveTranscriptText(state: TranscriptState): string {
  const finalText = state.finalText.trim();
  if (finalText.length > 0) {
    return finalText;
  }
  return state.partialText.trim();
}

function mergeTranscriptText(
  previous: string,
  incoming: string,
  preferReplacementWhenNoOverlap: boolean,
): string {
  const base = previous.trim();
  const next = incoming.trim();
  if (base.length === 0) {
    return next;
  }
  if (next.length === 0 || base === next) {
    return base;
  }
  if (next.startsWith(base) || next.includes(base)) {
    return next;
  }
  if (base.startsWith(next) || base.includes(next)) {
    return base;
  }
  if (base.endsWith(next)) {
    return base;
  }
  const overlapLength = longestSuffixPrefixOverlap(base, next);
  if (overlapLength > 0) {
    return `${base}${next.substring(overlapLength)}`;
  }
  if (preferReplacementWhenNoOverlap && next.length >= base.length) {
    return next;
  }
  return `${base}${next}`;
}

function longestSuffixPrefixOverlap(left: string, right: string): number {
  const maxLength = Math.min(left.length, right.length);
  for (let length = maxLength; length > 0; length -= 1) {
    if (left.endsWith(right.substring(0, length))) {
      return length;
    }
  }
  return 0;
}

export const LIVE_INPUT_SAMPLE_RATE = 16_000;
export const LIVE_OUTPUT_SAMPLE_RATE = 24_000;
export const LIVE_PCM_INPUT_MIME = `audio/pcm;rate=${LIVE_INPUT_SAMPLE_RATE}`;
export const LIVE_PCM_OUTPUT_MIME = `audio/pcm;rate=${LIVE_OUTPUT_SAMPLE_RATE}`;

export type ClientControlMessage =
  | {
      type: "session.start";
      threadId: string;
      resumeSessionId?: string | null;
      resumeHandle?: string | null;
    }
  | {
      type: "session.stop";
    }
  | {
      type: "audio.flush";
    }
  | {
      type: "client.ping";
      ts?: int | null;
    };

export type ServerControlMessage =
  | {
      type: "session.ready";
      sessionId: string;
      threadId: string;
      model: string;
      resumed: boolean;
      fallbackUsed: boolean;
      acceptance: string[];
    }
  | {
      type: "session.resumption";
      sessionId: string;
      handle: string | null;
      resumable: boolean;
      lastConsumedClientMessageIndex?: string | null;
    }
  | {
      type: "transcript.input.partial";
      turnId: string;
      text: string;
    }
  | {
      type: "transcript.input.final";
      turnId: string;
      text: string;
    }
  | {
      type: "transcript.output.partial";
      turnId: string;
      text: string;
    }
  | {
      type: "transcript.output.final";
      turnId: string;
      text: string;
    }
  | {
      type: "assistant.interrupted";
      turnId: string;
    }
  | {
      type: "assistant.turn_complete";
      turnId: string;
    }
  | {
      type: "session.waiting_for_input";
      turnId: string;
    }
  | {
      type: "session.goaway";
      timeLeft?: string;
    }
  | {
      type: "client.pong";
      ts?: int | null;
    }
  | {
      type: "error";
      code: string;
      detail?: string;
      retryable?: boolean;
    }
  | {
      type: "session.closed";
      code?: number;
      reason?: string;
    };

export type ParsedClientMessage =
  | { kind: "control"; message: ClientControlMessage }
  | { kind: "audio"; audioBytes: Buffer };

type int = number;

export function parseClientMessage(raw: Buffer | string): ParsedClientMessage {
  if (typeof raw !== "string") {
    return { kind: "audio", audioBytes: raw };
  }

  const parsed = JSON.parse(raw) as Record<string, unknown>;
  if (typeof parsed.type !== "string") {
    throw new Error("client_message_missing_type");
  }

  switch (parsed.type) {
    case "session.start":
      return {
        kind: "control",
        message: {
          type: "session.start",
          threadId: String(parsed.threadId ?? "").trim(),
          resumeSessionId:
            typeof parsed.resumeSessionId === "string"
              ? parsed.resumeSessionId
              : null,
          resumeHandle:
            typeof parsed.resumeHandle === "string" ? parsed.resumeHandle : null,
        },
      };
    case "session.stop":
      return { kind: "control", message: { type: "session.stop" } };
    case "audio.flush":
      return { kind: "control", message: { type: "audio.flush" } };
    case "client.ping":
      return {
        kind: "control",
        message: {
          type: "client.ping",
          ts: typeof parsed.ts === "number" ? parsed.ts : null,
        },
      };
    default:
      throw new Error(`unsupported_client_message:${parsed.type}`);
  }
}

export function serializeServerMessage(message: ServerControlMessage): string {
  return JSON.stringify(message);
}

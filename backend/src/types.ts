export type AuthedUser = {
  uid: string;
};

export type SessionResponse = {
  userId: string;
  needsOnboarding: boolean;
  characterId?: string;
  threadId?: string;
};

export type CharacterDraft = {
  name: string;
  personaPrompt: string;
  visualPromptBase: string;
  starterGreeting: string;
};

export type ImageDraft = {
  title: string;
  promptExcerpt: string;
  imageUrl?: string | null;
};

export type DailySummaryDraft = {
  dateKey: string;
  title: string;
  mood: string;
  doneThings: string[];
  reflection: string;
  tomorrowNote: string;
};

export type StoredDailySummary = DailySummaryDraft & {
  generatedAt?: unknown;
};


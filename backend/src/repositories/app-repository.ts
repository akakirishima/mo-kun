import { Firestore } from "firebase-admin/firestore";
import { Timestamp } from "../lib/firebase.js";
import {
  CharacterDraft,
  DailyBubbleDraft,
  DailySummaryDraft,
  ImageDraft,
  SessionResponse,
  StoredDailyBubble,
  StoredDailySummary,
} from "../types.js";
import { buildAppDateWindow } from "../services/app-date.js";

export type StoredMessage = {
  id: string;
  role?: string;
  text?: string;
  inputType?: string;
  [key: string]: unknown;
};

export class AppRepository {
  constructor(private readonly db: Firestore) {}

  async initializeSession(userId: string): Promise<SessionResponse> {
    const userRef = this.db.collection("users").doc(userId);
    const characterRef = this.db.collection("characters").doc(userId);
    const threadRef = this.db.collection("chatThreads").doc(`${userId}_main`);

    const [userDoc, characterDoc, threadDoc] = await Promise.all([
      userRef.get(),
      characterRef.get(),
      threadRef.get(),
    ]);

    if (!userDoc.exists) {
      const now = Timestamp.now();
      await userRef.set({
        createdAt: now,
        updatedAt: now,
        onboardingState: "pending",
      });
    }

    return {
      userId,
      needsOnboarding: !characterDoc.exists,
      characterId: characterDoc.exists ? characterRef.id : undefined,
      threadId: threadDoc.exists ? threadRef.id : undefined,
    };
  }

  async createCharacter(params: {
    userId: string;
    profile: {
      displayName: string;
      goal: string;
      partnerStyle: string;
      weakPoints: string[];
    };
    character: CharacterDraft;
  }) {
    const now = Timestamp.now();
    const threadId = `${params.userId}_main`;
    const userRef = this.db.collection("users").doc(params.userId);
    const characterRef = this.db.collection("characters").doc(params.userId);
    const threadRef = this.db.collection("chatThreads").doc(threadId);
    const starterRef = threadRef.collection("messages").doc();

    await this.db.runTransaction(async (transaction) => {
      transaction.set(
        userRef,
        {
          displayName: params.profile.displayName,
          goal: params.profile.goal,
          partnerStyle: params.profile.partnerStyle,
          weakPoints: params.profile.weakPoints,
          onboardingState: "completed",
          updatedAt: now,
        },
        { merge: true },
      );
      transaction.set(characterRef, {
        userId: params.userId,
        name: params.character.name,
        personaPrompt: params.character.personaPrompt,
        visualPromptBase: params.character.visualPromptBase,
        starterGreeting: params.character.starterGreeting,
        imageGenerationStatus: "idle",
        createdAt: now,
        updatedAt: now,
      });
      transaction.set(threadRef, {
        userId: params.userId,
        createdAt: now,
        updatedAt: now,
        lastMessageAt: now,
      });
      transaction.set(starterRef, {
        role: "assistant",
        text: params.character.starterGreeting,
        inputType: "text",
        createdAt: now,
      });
    });

    return { characterId: characterRef.id, threadId };
  }

  async getCharacterContext(userId: string) {
    const characterDoc = await this.db.collection("characters").doc(userId).get();
    return characterDoc.data() ?? null;
  }

  async updateVisualEvolutionMemo(params: {
    userId: string;
    visualEvolutionMemo: string;
  }) {
    const now = Timestamp.now();
    await this.db.collection("characters").doc(params.userId).set(
      {
        visualEvolutionMemo: params.visualEvolutionMemo,
        visualEvolutionUpdatedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  async getThreadOwner(threadId: string): Promise<string | null> {
    const threadDoc = await this.db.collection("chatThreads").doc(threadId).get();
    if (!threadDoc.exists) {
      return null;
    }

    const userId = threadDoc.get("userId");
    return typeof userId === "string" ? userId : null;
  }

  async getRecentMessages(threadId: string, limit = 20) {
    const snapshot = await this.db
      .collection("chatThreads")
      .doc(threadId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();
    return snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }) as StoredMessage)
      .reverse();
  }

  async getMessagesForDateKey(threadId: string, dateKey: string) {
    const { startAt, endAt } = buildAppDateWindow(dateKey);
    const snapshot = await this.db
      .collection("chatThreads")
      .doc(threadId)
      .collection("messages")
      .where("createdAt", ">=", Timestamp.fromDate(startAt))
      .where("createdAt", "<", Timestamp.fromDate(endAt))
      .orderBy("createdAt", "asc")
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }) as StoredMessage);
  }

  async appendConversation(params: {
    threadId: string;
    userId: string;
    userText: string;
    clientMessageId: string;
    assistantText: string;
    userInputType?: "text" | "voice";
  }) {
    const userCreatedAt = Timestamp.now();
    const assistantCreatedAt = Timestamp.fromMillis(Date.now() + 1);
    const threadRef = this.db.collection("chatThreads").doc(params.threadId);
    const userRef = threadRef.collection("messages").doc();
    const assistantRef = threadRef.collection("messages").doc();

    await this.db.runTransaction(async (transaction) => {
      transaction.set(userRef, {
        role: "user",
        text: params.userText,
        inputType: params.userInputType ?? "text",
        clientMessageId: params.clientMessageId,
        createdAt: userCreatedAt,
      });
      transaction.set(assistantRef, {
        role: "assistant",
        text: params.assistantText,
        inputType: "text",
        createdAt: assistantCreatedAt,
      });
      transaction.set(
        threadRef,
        {
          userId: params.userId,
          updatedAt: assistantCreatedAt,
          lastMessageAt: assistantCreatedAt,
        },
        { merge: true },
      );
    });

    return {
      userMessageId: userRef.id,
      assistantMessageId: assistantRef.id,
    };
  }

  async saveCharacterImage(params: {
    userId: string;
    image: ImageDraft;
    status?: "idle" | "generating" | "ready" | "failed";
    visualEvolutionMemo?: string;
    dateKey?: string;
  }) {
    const now = Timestamp.now();
    const characterRef = this.db.collection("characters").doc(params.userId);
    const historyRef = characterRef.collection("imageHistory").doc();
    const characterUpdate: Record<string, unknown> = {
      imageGenerationStatus: params.status ?? "ready",
      updatedAt: now,
    };

    if (params.visualEvolutionMemo != null) {
      characterUpdate.visualEvolutionMemo = params.visualEvolutionMemo;
      characterUpdate.visualEvolutionUpdatedAt = now;
    }

    if ((params.status ?? "ready") === "ready") {
      characterUpdate.lastGeneratedImageUrl = params.image.imageUrl ?? null;
      characterUpdate.lastImageGeneratedAt = now;
      characterUpdate.lastVisualPrompt = params.image.promptExcerpt;
    }

    await this.db.runTransaction(async (transaction) => {
      transaction.set(characterRef, characterUpdate, { merge: true });
      transaction.set(historyRef, {
        title: params.image.title,
        promptExcerpt: params.image.promptExcerpt,
        imageUrl: params.image.imageUrl ?? null,
        status: params.status ?? "ready",
        generatedAt: now,
        dateKey: params.dateKey ?? params.image.dateKey ?? null,
      });
    });
  }

  async markCharacterImageGenerating(params: {
    userId: string;
    visualEvolutionMemo?: string;
  }) {
    const now = Timestamp.now();
    const update: Record<string, unknown> = {
      imageGenerationStatus: "generating",
      updatedAt: now,
    };
    if (params.visualEvolutionMemo != null) {
      update.visualEvolutionMemo = params.visualEvolutionMemo;
      update.visualEvolutionUpdatedAt = now;
    }
    await this.db.collection("characters").doc(params.userId).set(update, {
      merge: true,
    });
  }

  async saveDailySummary(userId: string, summary: DailySummaryDraft) {
    const summaryRef = this.db
      .collection("users")
      .doc(userId)
      .collection("dailySummaries")
      .doc(summary.dateKey);
    await summaryRef.set({
      ...summary,
      generatedAt: Timestamp.now(),
    });
  }

  async getDailySummary(userId: string, dateKey: string): Promise<StoredDailySummary | null> {
    const snapshot = await this.db
      .collection("users")
      .doc(userId)
      .collection("dailySummaries")
      .doc(dateKey)
      .get();

    if (!snapshot.exists) {
      return null;
    }

    return { ...snapshot.data(), dateKey } as StoredDailySummary;
  }

  async getDailyBubble(userId: string, dateKey: string): Promise<StoredDailyBubble | null> {
    const snapshot = await this.db
      .collection("users")
      .doc(userId)
      .collection("dailyBubbles")
      .doc(dateKey)
      .get();

    if (!snapshot.exists) {
      return null;
    }

    return { ...snapshot.data(), dateKey } as StoredDailyBubble;
  }

  async saveDailyBubble(userId: string, bubble: DailyBubbleDraft) {
    const bubbleRef = this.db
      .collection("users")
      .doc(userId)
      .collection("dailyBubbles")
      .doc(bubble.dateKey);
    await bubbleRef.set({
      ...bubble,
      generatedAt: Timestamp.now(),
    });
  }

  async listRecentDailySummaries(userId: string, limit = 7): Promise<StoredDailySummary[]> {
    const snapshot = await this.db
      .collection("users")
      .doc(userId)
      .collection("dailySummaries")
      .orderBy("generatedAt", "desc")
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => ({ ...doc.data(), dateKey: doc.id }) as StoredDailySummary);
  }

  async listUsersForRefresh() {
    const snapshot = await this.db.collection("users").get();
    return snapshot.docs.map((doc) => doc.id);
  }
}

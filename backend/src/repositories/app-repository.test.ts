import assert from "node:assert/strict";
import { AppRepository } from "./app-repository.js";

class FakeDocRef {
  constructor(
    private readonly store: FakeFirestore,
    readonly path: string,
  ) {}

  collection(name: string) {
    return new FakeCollectionRef(this.store, `${this.path}/${name}`);
  }

  async set(
    data: Record<string, unknown>,
    options?: { merge?: boolean },
  ) {
    this.store.set(this.path, data, options);
  }
}

class FakeCollectionRef {
  constructor(
    private readonly store: FakeFirestore,
    readonly path: string,
  ) {}

  doc(id?: string) {
    const docId = id ?? this.store.nextId();
    return new FakeDocRef(this.store, `${this.path}/${docId}`);
  }
}

class FakeFirestore {
  private readonly docs = new Map<string, Record<string, unknown>>();
  private autoId = 0;

  collection(name: string) {
    return new FakeCollectionRef(this, name);
  }

  nextId() {
    this.autoId += 1;
    return `auto-${this.autoId}`;
  }

  set(
    path: string,
    data: Record<string, unknown>,
    options?: { merge?: boolean },
  ) {
    const existing = this.docs.get(path) ?? {};
    this.docs.set(path, options?.merge ? { ...existing, ...data } : { ...data });
  }

  get(path: string) {
    return this.docs.get(path) ?? null;
  }

  async runTransaction(
    callback: (transaction: {
      set: (
        ref: FakeDocRef,
        data: Record<string, unknown>,
        options?: { merge?: boolean },
      ) => void;
    }) => Promise<void>,
  ) {
    await callback({
      set: (ref, data, options) => {
        this.set(ref.path, data, options);
      },
    });
  }
}

const db = new FakeFirestore();
const repository = new AppRepository(db as never);

db.set("characters/test-user", {
  lastGeneratedSquareVideoUrl: "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
  lastGeneratedVideoUrl: "gs://demo-bucket/characters/test-user/videoHistory/previous.mp4",
});

await repository.markCharacterVideoGenerating({
  userId: "test-user",
  posterImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
});

assert.deepEqual(db.get("characters/test-user"), {
  lastGeneratedSquareVideoUrl:
    "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
  lastGeneratedVideoUrl: "gs://demo-bucket/characters/test-user/videoHistory/previous.mp4",
  videoGenerationStatus: "generating",
  lastVideoPosterImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
  updatedAt: db.get("characters/test-user")?.updatedAt,
});

await repository.saveCharacterVideo({
  userId: "test-user",
  status: "ready",
  sourceImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
  video: {
    title: "更新した姿の動画",
    promptExcerpt: "motion excerpt",
    videoUrl: "gs://demo-bucket/characters/test-user/videoHistory/fresh.mp4",
    squareVideoUrl: null,
    posterImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
    dateKey: "2026-03-20",
  },
});

const afterNullSquareSave = db.get("characters/test-user");
assert.equal(
  afterNullSquareSave?.lastGeneratedSquareVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/previous-square.mp4",
);
assert.equal(
  afterNullSquareSave?.lastGeneratedVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/fresh.mp4",
);

await repository.saveCharacterVideo({
  userId: "test-user",
  status: "ready",
  sourceImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
  video: {
    title: "更新した姿の動画",
    promptExcerpt: "motion excerpt",
    videoUrl: "gs://demo-bucket/characters/test-user/videoHistory/fresh.mp4",
    squareVideoUrl: "gs://demo-bucket/characters/test-user/videoHistory/fresh-square.mp4",
    posterImageUrl: "gs://demo-bucket/characters/test-user/imageHistory/demo.png",
    dateKey: "2026-03-20",
  },
});

assert.equal(
  db.get("characters/test-user")?.lastGeneratedSquareVideoUrl,
  "gs://demo-bucket/characters/test-user/videoHistory/fresh-square.mp4",
);

console.log("app-repository tests passed");

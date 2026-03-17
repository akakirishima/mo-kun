# Backend Implementation Notes

## Current shape
- Flutter app now boots through `AppBootstrapScreen`.
- `App` uses a repository abstraction.
- `main.dart` attempts to create `FirebaseAppRepository` and falls back to a fake repository if Firebase is not configured yet.
- `Home` chat uses repository-backed send and stream updates with optimistic pending messages.
- `Diary` reads AI-generated daily summaries.
- `Image` reads latest character image status and image history.
- `POST /v1/chat/messages` now uses Gemini on Vertex AI for assistant replies.

## Firebase / GCP setup still required
- Register Android/iOS apps in Firebase and add native config files.
- Enable Anonymous Auth, Firestore, Cloud Run, Cloud Scheduler, Vertex AI, Secret Manager, and Cloud Storage in the target project.
- Deploy the Cloud Run service under `backend/`.
- Set `BACKEND_BASE_URL` for Flutter builds.

## Gemini chat deployment notes
- Backend chat now depends on `@google/genai` and the Cloud Run service account being able to call Vertex AI.
- Required env vars for Cloud Run:
  - `GOOGLE_CLOUD_PROJECT`
  - `VERTEX_LOCATION`
  - `GEMINI_MODEL`
  - `GEMINI_TEMPERATURE`
  - `GEMINI_MAX_OUTPUT_TOKENS`
- Recommended initial values:
  - `VERTEX_LOCATION=global`
  - `GEMINI_MODEL=gemini-2.5-flash`
  - `GEMINI_TEMPERATURE=0.7`
  - `GEMINI_MAX_OUTPUT_TOKENS=220`
- `gemini-2.0-flash` is no longer usable in this project setup. Use `gemini-2.5-flash`.
- `/v1/chat/messages` returns `503 assistant_generation_failed` when Gemini fails. Flutter should surface this as a retryable send failure instead of falling back to fake text.

## Firestore document expectations
- `users/{uid}`
  - `createdAt`
  - `updatedAt`
- `users/{uid}/dailySummaries/{dateKey}`
  - `title`
  - `mood`
  - `doneThings`
  - `reflection`
  - `tomorrowNote`
  - `generatedAt`
- `characters/{uid}`
  - `userId`
  - `name`
  - `personaPrompt`
  - `visualPromptBase`
  - `starterGreeting`
  - `imageGenerationStatus`
  - `lastGeneratedImageUrl`
  - `lastImageGeneratedAt`
- `characters/{uid}/imageHistory/{imageId}`
  - `title`
  - `promptExcerpt`
  - `status`
  - `generatedAt`
  - `imageUrl`
- `chatThreads/{threadId}`
  - `userId`
  - `createdAt`
  - `updatedAt`
- `chatThreads/{threadId}/messages/{messageId}`
  - `role`
  - `text`
  - `clientMessageId`
  - `createdAt`

## Notes
- The fake repository keeps widget tests stable and gives a local preview without Firebase credentials.
- Production flows depend on the backend returning `threadId`, `characterId`, and writing `clientMessageId` into stored user messages so optimistic updates can resolve cleanly.
- Chat writes are now protected in two layers:
  - Firestore Rules prevent direct client writes to messages.
  - Backend verifies that the requested `threadId` belongs to the authenticated user before reading history or appending messages.

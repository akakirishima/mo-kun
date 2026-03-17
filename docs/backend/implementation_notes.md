# Backend Implementation Notes

## Current shape
- Flutter app now boots through `AppBootstrapScreen`.
- `App` uses a repository abstraction.
- `main.dart` attempts to create `FirebaseAppRepository` and falls back to a fake repository if Firebase is not configured yet.
- `Home` chat uses repository-backed send and stream updates with optimistic pending messages.
- `Diary` reads AI-generated daily summaries.
- `Image` reads latest character image status and image history.

## Firebase / GCP setup still required
- Register Android/iOS apps in Firebase and add native config files.
- Enable Anonymous Auth, Firestore, Cloud Run, Cloud Scheduler, Vertex AI, Secret Manager, and Cloud Storage in the target project.
- Deploy the Cloud Run service under `backend/`.
- Set `BACKEND_BASE_URL` for Flutter builds.

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

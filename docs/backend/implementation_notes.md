# Backend Implementation Notes

## Current shape
- Flutter app now boots through `AppBootstrapScreen`.
- `App` uses a repository abstraction.
- `main.dart` attempts to create `FirebaseAppRepository` and falls back to a fake repository if Firebase is not configured yet.
- `HomeScreen` is the production chat UI. `ChatScreen` is no longer the live chat path.
- `Home` chat uses repository-backed send and stream updates with optimistic pending messages.
- `Diary` reads AI-generated daily summaries.
- `Image` reads latest character image status and image history, and can trigger manual regeneration.
- `POST /v1/chat/messages` now uses Gemini on Vertex AI for assistant replies.
- `POST /v1/characters/image` now uses Gemini image generation plus Cloud Storage persistence.
- `Home` also renders the latest generated character image when available.

## Firebase / GCP setup still required
- Register Android/iOS apps in Firebase and add native config files.
- Enable Anonymous Auth, Firestore, Cloud Run, Cloud Scheduler, Vertex AI, Secret Manager, and Cloud Storage in the target project.
- Deploy the Cloud Run service under `backend/`.
- Set `BACKEND_BASE_URL` for Flutter builds.

## Gemini deployment notes
- Backend chat and image generation now depend on `@google/genai` and the Cloud Run service account being able to call Vertex AI.
- Required env vars for Cloud Run:
  - `GOOGLE_CLOUD_PROJECT`
  - `VERTEX_LOCATION`
  - `GEMINI_MODEL`
  - `GEMINI_IMAGE_MODEL`
  - `GEMINI_TEMPERATURE`
  - `GEMINI_MAX_OUTPUT_TOKENS`
  - `IMAGE_BUCKET`
- Recommended initial values:
  - `VERTEX_LOCATION=global`
  - `GEMINI_MODEL=gemini-2.5-flash`
  - `GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`
  - `GEMINI_TEMPERATURE=0.7`
  - `GEMINI_MAX_OUTPUT_TOKENS=220`
- `IMAGE_BUCKET` should be the Firebase Storage bucket name without `gs://`.
- `gemini-2.0-flash` is no longer usable in this project setup. Use `gemini-2.5-flash` for chat and `gemini-2.5-flash-image` for image generation.
- `/v1/chat/messages` returns `503 assistant_generation_failed` when Gemini fails. Flutter should surface this as a retryable send failure instead of falling back to fake text.
- `/v1/characters/image` returns `503 generate_image_failed` when Gemini image generation fails.

## Image generation flow
- `backend/src/index.ts` is the source of truth for backend wiring.
- `AiService` handles:
  - assistant chat generation
  - `visualEvolutionMemo` generation from recent daily summaries
  - final image prompt construction
  - Gemini image generation
- `CharacterImageService` handles:
  - reading the character and recent summaries
  - computing the app date key with the exact `03:00 JST` boundary
  - fallback summary generation when the current day summary is missing
  - Cloud Storage upload
  - Firestore status / history updates

The final image prompt is composed from:
- `visualPromptBase`
- `visualEvolutionMemo`
- the current daily summary
- an optional one-off note from manual regenerate
- continuity rules that keep the same character identity stable across days

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
  - `visualEvolutionMemo`
  - `visualEvolutionUpdatedAt`
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
- Image generation builds the final prompt from:
  - `visualPromptBase`
  - the latest `visualEvolutionMemo`
  - the current daily summary
  - an optional one-off note from the manual regenerate UI
- `visualEvolutionMemo` is rebuilt from the latest 7 daily summaries and persisted on the character document.
- The app and backend both use `03:00 JST` as the day boundary for daily refresh.
- Generated image files live in Cloud Storage and Firestore stores `gs://...` references plus image history metadata.
- Flutter resolves `gs://` URLs through Firebase Storage before rendering them in `ImageScreen` and `HomeScreen`.
- Chat writes are now protected in two layers:
  - Firestore Rules prevent direct client writes to messages.
  - Backend verifies that the requested `threadId` belongs to the authenticated user before reading history or appending messages.

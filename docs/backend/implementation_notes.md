# Backend Implementation Notes

## Current shape
- Flutter app now boots through `AppBootstrapScreen`.
- `App` uses a repository abstraction.
- `main.dart` attempts to create `FirebaseAppRepository` and falls back to a fake repository if Firebase is not configured yet.
- `HomeScreen` is the production conversation UI and the main flow now lives there.
- `Home` renders the latest character image when available, a daily speech bubble, and `voice / photo / chat` actions.
- `Home` chat uses repository-backed send and stream updates with optimistic pending messages.
- `Home` voice mode uses push-to-talk recording and backend round-trips.
- `Diary` reads AI-generated daily summaries.
- `Image` reads latest character image status and image history, and can trigger manual regeneration.
- `POST /v1/chat/messages` uses Gemini on Vertex AI for assistant replies.
- `POST /v1/chat/voice` uses Speech-to-Text, Gemini, and Text-to-Speech for a voice round-trip.
- `POST /v1/characters/image` uses Gemini image generation plus Cloud Storage persistence.
- `daily bubble` generation is persisted in Firestore and is based on the previous day summary.
- onboarding stores `age / characterGender / appearancePreset` and uses them for initial visual generation.

## Product concept
- The current concept is not an AI partner.
- The character is treated as a self-projection of the user.
- The response style should feel like `自分の内なる声`, not a mascot or companion.
- UI wording should avoid fixed names like `Mori`.

## Firebase / GCP setup still required
- Register Android/iOS apps in Firebase and add native config files.
- Enable Anonymous Auth, Firestore, Cloud Run, Cloud Scheduler, Vertex AI, Speech-to-Text, Text-to-Speech, Secret Manager, and Cloud Storage in the target project.
- Deploy the Cloud Run service under `backend/`.
- Set `BACKEND_BASE_URL` for Flutter builds.

## Gemini / Speech deployment notes
- Backend chat and image generation depend on `@google/genai` and the Cloud Run service account being able to call Vertex AI.
- Backend voice chat depends on `@google-cloud/speech` and `@google-cloud/text-to-speech`.
- Required env vars for Cloud Run:
  - `GOOGLE_CLOUD_PROJECT`
  - `VERTEX_LOCATION`
  - `GEMINI_MODEL`
  - `GEMINI_IMAGE_MODEL`
  - `GEMINI_TEMPERATURE`
  - `GEMINI_MAX_OUTPUT_TOKENS`
  - `GEMINI_THINKING_BUDGET`
  - `DAILY_SUMMARY_TEMPERATURE`
  - `DAILY_SUMMARY_MAX_OUTPUT_TOKENS`
  - `DAILY_SUMMARY_THINKING_BUDGET`
  - `DAILY_BUBBLE_TEMPERATURE`
  - `DAILY_BUBBLE_MAX_OUTPUT_TOKENS`
  - `DAILY_BUBBLE_THINKING_BUDGET`
  - `IMAGE_BUCKET`
  - `SPEECH_LANGUAGE_CODE`
  - `TTS_LANGUAGE_CODE`
  - `TTS_MODEL_NAME`
  - `TTS_AUDIO_ENCODING`
- Recommended initial values:
  - `VERTEX_LOCATION=global`
  - `GEMINI_MODEL=gemini-2.5-pro`
  - `GEMINI_IMAGE_MODEL=gemini-2.5-flash-image`
  - `GEMINI_TEMPERATURE=0.7`
  - `GEMINI_MAX_OUTPUT_TOKENS=220`
  - `GEMINI_THINKING_BUDGET=128`
  - `DAILY_SUMMARY_TEMPERATURE=0.35`
  - `DAILY_SUMMARY_MAX_OUTPUT_TOKENS=320`
  - `DAILY_SUMMARY_THINKING_BUDGET=128`
  - `DAILY_BUBBLE_TEMPERATURE=0.45`
  - `DAILY_BUBBLE_MAX_OUTPUT_TOKENS=120`
  - `DAILY_BUBBLE_THINKING_BUDGET=32`
  - `SPEECH_LANGUAGE_CODE=ja-JP`
  - `TTS_LANGUAGE_CODE=ja-JP`
  - `TTS_MODEL_NAME=gemini-2.5-flash-tts`
  - `TTS_AUDIO_ENCODING=MP3`
- `IMAGE_BUCKET` should be the Firebase Storage bucket name without `gs://`.
- `TTS_VOICE_NAME` defaults to `Kore`.
- `TTS_PROMPT` is optional and defaults to a calm inner-voice prompt.
- `/v1/chat/messages` returns a fallback assistant reply when Gemini fails after photo analysis, and `503 assistant_generation_failed` only when no safe fallback can be built.
- `/v1/characters/image` returns `503 generate_image_failed` when Gemini image generation fails.
- `/v1/chat/voice` may succeed partially: if TTS fails after the assistant text was generated and stored, the response returns text with `audioStatus=failed`.

## Current backend flows
### Text chat
1. Verify Firebase ID token
2. Verify thread ownership
3. Read thread history
4. Generate assistant reply with Gemini
5. Store user / assistant messages
6. Rebuild the current daily summary

### Voice chat
1. Verify Firebase ID token
2. Verify thread ownership
3. Accept multipart audio upload
4. Run Speech-to-Text
5. Generate assistant reply with Gemini
6. Store the user transcript with `inputType=voice`
7. Store the assistant text reply
8. Rebuild the current daily summary
9. Run Text-to-Speech
10. Return transcript, assistant text, and assistant audio

### Daily bubble
1. Resolve the app date key with `03:00 JST` cutover
2. Read the previous day summary when available
3. Generate a short daily bubble text
4. Persist it to `users/{uid}/dailyBubbles/{dateKey}`
5. Reuse the same bubble within the same day

### Image generation flow
- `backend/src/index.ts` is the source of truth for backend wiring.
- `AiService` handles:
  - assistant chat generation
  - daily bubble generation
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
- the current `appearancePreset`
- age / character gender visual hints
- `visualEvolutionMemo`
- the current daily summary
- an optional one-off note from manual regenerate
- continuity rules that keep the same character identity stable across days

## Firestore document expectations
### `users/{uid}`
- `createdAt`
- `updatedAt`
- `age`
- `characterGender`
- `appearancePreset`

### `users/{uid}/dailySummaries/{dateKey}`
- `title`
- `mood`
- `doneThings`
- `reflection`
- `tomorrowNote`
- `generatedAt`

### `users/{uid}/dailyBubbles/{dateKey}`
- `text`
- `generatedAt`
- `sourceDateKey`

### `characters/{uid}`
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

### `characters/{uid}/imageHistory/{imageId}`
- `title`
- `promptExcerpt`
- `status`
- `generatedAt`
- `imageUrl`

### `chatThreads/{threadId}`
- `userId`
- `createdAt`
- `updatedAt`

### `chatThreads/{threadId}/messages/{messageId}`
- `role`
- `text`
- `inputType`
- `clientMessageId`
- `createdAt`

## Notes
- The fake repository keeps widget tests stable and gives a local preview without Firebase credentials.
- Production flows depend on the backend returning `threadId`, `characterId`, and writing `clientMessageId` into stored user messages so optimistic updates can resolve cleanly.
- Generated image files live in Cloud Storage and Firestore stores `gs://...` references plus image history metadata.
- Flutter resolves `gs://` URLs through Firebase Storage before rendering them in `ImageScreen` and `HomeScreen`.
- Chat writes are protected in two layers:
  - Firestore Rules prevent direct client writes to messages.
  - Backend verifies that the requested `threadId` belongs to the authenticated user before reading history or appending messages.

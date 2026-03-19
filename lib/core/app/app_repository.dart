import 'dart:typed_data';

import 'dart:async';

import 'package:gdgoc_2026_prototype/core/app/app_models.dart';

abstract class AppRepository {
  Future<AppSession> initializeSession();

  Future<AppSession> completeOnboarding(UserProfileInput input);

  Stream<List<ChatMessage>> watchChatMessages(String threadId);

  Future<void> sendChatMessage({
    required String threadId,
    required String text,
    required String clientMessageId,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? imageFilename,
  });

  Future<VoiceChatResult> sendVoiceMessage({
    required String threadId,
    required Uint8List audioBytes,
    required String mimeType,
    required int durationMs,
    required String clientMessageId,
  });

  Future<void> regenerateCharacterImage({String? title, String? reportText});

  Stream<CharacterSnapshot?> watchCharacter(String characterId);

  Stream<List<CharacterImageVersion>> watchImageHistory(String characterId);

  Stream<List<CharacterImageVersion>> watchDiaryImageHistory({
    required String characterId,
    required DateTime month,
  });

  Stream<DailySummary?> watchDailySummary({
    required String userId,
    required String dateKey,
  });

  Stream<DailyBubble?> watchDailyBubble({
    required String userId,
    required String dateKey,
  });

  Stream<List<DailySummary>> watchMonthlyDailySummaries({
    required String userId,
    required DateTime month,
  });

  Future<void> dispose() async {}
}

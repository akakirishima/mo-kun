import 'dart:typed_data';

import 'dart:async';

import 'package:gdgoc_2026_prototype/core/app/app_models.dart';

abstract class AppRepository {
  Future<AppSession> initializeSession();

  Future<AppSession> completeOnboarding(UserProfileInput input);

  Stream<UserProfileInput?> watchUserProfile(String userId);

  Future<void> updateUserProfile({
    required String userId,
    required UserProfileInput profile,
  });

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

  Future<void> updateCharacterSettings({
    required String characterId,
    required CharacterSettings settings,
  });

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

  Stream<HomeBackgroundPreference?> watchHomeBackgroundPreference({
    required String userId,
  });

  Future<void> selectHomeBackgroundTheme({
    required String userId,
    required String themeId,
  });

  Future<void> uploadCustomHomeBackground({
    required String userId,
    required Uint8List imageBytes,
    required String imageMimeType,
    required String imageFilename,
  });

  Future<void> dispose() async {}
}

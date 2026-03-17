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

  Stream<List<DailySummary>> watchMonthlyDailySummaries({
    required String userId,
    required DateTime month,
  });

  Future<void> dispose() async {}
}

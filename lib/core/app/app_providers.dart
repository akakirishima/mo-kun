import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  throw UnimplementedError('AppRepository must be overridden.');
});

final imageUrlResolverProvider = Provider<ImageUrlResolver>((ref) {
  return ImageUrlResolver();
});

final sessionProvider = FutureProvider<AppSession>((ref) {
  return ref.watch(appRepositoryProvider).initializeSession();
});

final currentAppDateProvider = Provider<DateTime>((ref) {
  return resolveAppDate(DateTime.now());
});

final currentDateKeyProvider = Provider<String>((ref) {
  return buildAppDateKeyFromDateTime(DateTime.now());
});

final currentDiaryMonthProvider = Provider<DateTime>((ref) {
  final appDate = ref.watch(currentAppDateProvider);
  return appMonthStart(appDate);
});

final selectedDiaryMonthProvider = StateProvider<DateTime>((ref) {
  return ref.watch(currentDiaryMonthProvider);
});

final diaryMonthNavigationControllerProvider =
    Provider<DiaryMonthNavigationController>(
      (ref) => DiaryMonthNavigationController(ref),
    );

class DiaryMonthNavigationController {
  DiaryMonthNavigationController(this._ref);

  final Ref _ref;

  DateTime get currentMonth => _ref.read(currentDiaryMonthProvider);

  DateTime get selectedMonth =>
      appMonthStart(_ref.read(selectedDiaryMonthProvider));

  bool get canShowNextMonth => selectedMonth.isBefore(currentMonth);

  void setMonth(DateTime month) {
    final normalized = appMonthStart(month);
    _ref.read(selectedDiaryMonthProvider.notifier).state =
        normalized.isAfter(currentMonth) ? currentMonth : normalized;
  }

  void showPreviousMonth() {
    setMonth(previousMonth(selectedMonth));
  }

  void showNextMonth() {
    if (!canShowNextMonth) {
      return;
    }
    setMonth(nextMonth(selectedMonth));
  }
}

final characterProvider = StreamProvider.family<CharacterSnapshot?, String>((
  ref,
  characterId,
) {
  return ref.watch(appRepositoryProvider).watchCharacter(characterId);
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  threadId,
) {
  return ref.watch(appRepositoryProvider).watchChatMessages(threadId);
});

final imageHistoryProvider =
    StreamProvider.family<List<CharacterImageVersion>, String>((
      ref,
      characterId,
    ) {
      return ref.watch(appRepositoryProvider).watchImageHistory(characterId);
    });

final resolvedImageUrlProvider = FutureProvider.family<String?, String?>((
  ref,
  rawUrl,
) {
  return ref.watch(imageUrlResolverProvider).resolve(rawUrl);
});

final dailySummaryProvider = StreamProvider.family<DailySummary?, AppSession>((
  ref,
  session,
) {
  return ref
      .watch(appRepositoryProvider)
      .watchDailySummary(
        userId: session.userId,
        dateKey: ref.watch(currentDateKeyProvider),
      );
});

final dailyBubbleProvider = StreamProvider.family<DailyBubble?, AppSession>((
  ref,
  session,
) {
  return ref
      .watch(appRepositoryProvider)
      .watchDailyBubble(
        userId: session.userId,
        dateKey: ref.watch(currentDateKeyProvider),
      );
});

final monthlyDailySummariesProvider =
    StreamProvider.family<List<DailySummary>, AppSession>((ref, session) {
      return ref
          .watch(appRepositoryProvider)
          .watchMonthlyDailySummaries(
            userId: session.userId,
            month: ref.watch(selectedDiaryMonthProvider),
          );
    });

final diaryImageHistoryProvider =
    StreamProvider.family<List<CharacterImageVersion>, AppSession>((
      ref,
      session,
    ) {
      final characterId = session.characterId;
      if (characterId == null) {
        return Stream.value(const <CharacterImageVersion>[]);
      }
      return ref
          .watch(appRepositoryProvider)
          .watchDiaryImageHistory(
            characterId: characterId,
            month: ref.watch(selectedDiaryMonthProvider),
          );
    });

final pendingMessagesProvider =
    StateNotifierProvider<PendingMessagesController, List<PendingChatMessage>>((
      ref,
    ) {
      return PendingMessagesController();
    });

class PendingMessagesController
    extends StateNotifier<List<PendingChatMessage>> {
  PendingMessagesController() : super(const []);

  void add(PendingChatMessage message) {
    state = [...state, message];
  }

  void markFailed(String clientMessageId) {
    state = [
      for (final message in state)
        if (message.clientMessageId == clientMessageId)
          message.copyWith(failed: true)
        else
          message,
    ];
  }

  void markCompleted(Iterable<String> resolvedClientIds) {
    final resolved = resolvedClientIds.toSet();
    state = [
      for (final message in state)
        if (!resolved.contains(message.clientMessageId)) message,
    ];
  }
}

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(ref),
);

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  Future<AppSession> submit(UserProfileInput input) async {
    final session = await _ref
        .read(appRepositoryProvider)
        .completeOnboarding(input);
    _ref.invalidate(sessionProvider);
    return session;
  }
}

final sendChatMessageControllerProvider = Provider<SendChatMessageController>(
  (ref) => SendChatMessageController(ref),
);

class SendChatMessageController {
  SendChatMessageController(this._ref);

  final Ref _ref;

  Future<void> send({
    required AppSession session,
    required String text,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? imageFilename,
    String? localImagePath,
  }) async {
    final threadId = session.threadId;
    if (threadId == null) {
      throw StateError('Missing thread id.');
    }
    if (text.trim().isEmpty && imageBytes == null) {
      throw StateError('Message must contain text or photo.');
    }
    final now = DateTime.now();
    final clientMessageId = 'client-${now.microsecondsSinceEpoch}';
    final pending = PendingChatMessage(
      clientMessageId: clientMessageId,
      threadId: threadId,
      text: text,
      createdAt: now,
      failed: false,
      localImagePath: localImagePath,
    );
    _ref.read(pendingMessagesProvider.notifier).add(pending);
    try {
      await _ref
          .read(appRepositoryProvider)
          .sendChatMessage(
            threadId: threadId,
            text: text,
            clientMessageId: clientMessageId,
            imageBytes: imageBytes,
            imageMimeType: imageMimeType,
            imageFilename: imageFilename,
          );
    } catch (_) {
      _ref.read(pendingMessagesProvider.notifier).markFailed(clientMessageId);
      rethrow;
    }
  }
}

final regenerateCharacterImageControllerProvider =
    Provider<RegenerateCharacterImageController>(
      (ref) => RegenerateCharacterImageController(ref),
    );

class RegenerateCharacterImageController {
  RegenerateCharacterImageController(this._ref);

  final Ref _ref;

  Future<void> regenerate({String? title, String? reportText}) {
    return _ref
        .read(appRepositoryProvider)
        .regenerateCharacterImage(title: title, reportText: reportText);
  }
}

final sendVoiceMessageControllerProvider = Provider<SendVoiceMessageController>(
  (ref) => SendVoiceMessageController(ref),
);

class SendVoiceMessageController {
  SendVoiceMessageController(this._ref);

  final Ref _ref;

  Future<VoiceChatResult> send({
    required AppSession session,
    required Uint8List audioBytes,
    required String mimeType,
    required int durationMs,
  }) {
    final threadId = session.threadId;
    if (threadId == null) {
      throw StateError('Missing thread id.');
    }
    final now = DateTime.now();
    return _ref
        .read(appRepositoryProvider)
        .sendVoiceMessage(
          threadId: threadId,
          audioBytes: audioBytes,
          mimeType: mimeType,
          durationMs: durationMs,
          clientMessageId: 'voice-${now.microsecondsSinceEpoch}',
        );
  }
}

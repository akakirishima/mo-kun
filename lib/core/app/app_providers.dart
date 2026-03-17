import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  throw UnimplementedError('AppRepository must be overridden.');
});

final sessionProvider = FutureProvider<AppSession>((ref) {
  return ref.watch(appRepositoryProvider).initializeSession();
});

final currentDateKeyProvider = Provider<String>((ref) {
  final now = DateTime.now();
  final adjusted = now.hour < 3 ? now.subtract(const Duration(days: 1)) : now;
  final month = adjusted.month.toString().padLeft(2, '0');
  final day = adjusted.day.toString().padLeft(2, '0');
  return '${adjusted.year}-$month-$day';
});

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

  Future<void> send({required AppSession session, required String text}) async {
    final threadId = session.threadId;
    if (threadId == null) {
      throw StateError('Missing thread id.');
    }
    final now = DateTime.now();
    final clientMessageId = 'client-${now.microsecondsSinceEpoch}';
    final pending = PendingChatMessage(
      clientMessageId: clientMessageId,
      threadId: threadId,
      text: text,
      createdAt: now,
      failed: false,
    );
    _ref.read(pendingMessagesProvider.notifier).add(pending);
    try {
      await _ref
          .read(appRepositoryProvider)
          .sendChatMessage(
            threadId: threadId,
            text: text,
            clientMessageId: clientMessageId,
          );
    } catch (_) {
      _ref.read(pendingMessagesProvider.notifier).markFailed(clientMessageId);
      rethrow;
    }
  }
}

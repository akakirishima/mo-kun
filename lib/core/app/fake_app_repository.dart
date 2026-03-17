import 'dart:async';

import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';

class FakeAppRepository implements AppRepository {
  FakeAppRepository({
    AppSession? initialSession,
    CharacterSnapshot? initialCharacter,
    List<ChatMessage>? initialMessages,
    DailySummary? initialSummary,
    List<CharacterImageVersion>? initialImageHistory,
  }) : _session =
           initialSession ??
           const AppSession(userId: 'demo-user', needsOnboarding: true) {
    _character = initialCharacter;
    _messages = initialMessages ?? <ChatMessage>[];
    _summary = initialSummary;
    _imageHistory = initialImageHistory ?? <CharacterImageVersion>[];
    _emitAll();
  }

  final _chatController = StreamController<List<ChatMessage>>.broadcast();
  final _characterController = StreamController<CharacterSnapshot?>.broadcast();
  final _summaryController = StreamController<DailySummary?>.broadcast();
  final _imageHistoryController =
      StreamController<List<CharacterImageVersion>>.broadcast();

  AppSession _session;
  CharacterSnapshot? _character;
  List<ChatMessage> _messages = <ChatMessage>[];
  DailySummary? _summary;
  List<CharacterImageVersion> _imageHistory = <CharacterImageVersion>[];

  @override
  Future<AppSession> initializeSession() async => _session;

  @override
  Future<AppSession> completeOnboarding(UserProfileInput input) async {
    final now = DateTime.now();
    _character = CharacterSnapshot(
      id: 'character-${_session.userId}',
      name: input.displayName.isEmpty ? 'Mori' : '${input.displayName} Mori',
      personaPrompt:
          'You are a supportive partner who reflects progress gently.',
      visualPromptBase:
          'Soft illustrated companion, reflects recent self-improvement.',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: null,
      lastGeneratedAt: now,
      starterGreeting: '${input.displayName}、今日から一緒に進もう。',
    );
    _messages = <ChatMessage>[
      ChatMessage(
        id: 'starter',
        role: ChatRole.assistant,
        text: _character!.starterGreeting ?? '今日から一緒に進もう。',
        createdAt: now,
      ),
    ];
    _summary = DailySummary(
      dateKey: _dateKey(now),
      title: 'はじまりの日',
      mood: 'わくわく',
      doneThings: ['プロフィールを登録した', '相棒を迎えた'],
      reflection: '最初の一歩を踏み出した日。',
      tomorrowNote: 'まずは小さな報告を1つ送ってみよう。',
      generatedAt: now,
    );
    _imageHistory = <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'image-initial',
        title: '最初の姿',
        promptExcerpt: input.goal,
        status: CharacterImageStatus.ready,
        generatedAt: now,
      ),
    ];
    _session = _session.copyWith(
      needsOnboarding: false,
      characterId: _character!.id,
      threadId: 'thread-${_session.userId}',
    );
    _emitAll();
    return _session;
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String threadId) async* {
    yield List<ChatMessage>.unmodifiable(_messages);
    yield* _chatController.stream;
  }

  @override
  Future<void> sendChatMessage({
    required String threadId,
    required String text,
    required String clientMessageId,
  }) async {
    final now = DateTime.now();
    _messages = [
      ..._messages,
      ChatMessage(
        id: clientMessageId,
        role: ChatRole.user,
        text: text,
        createdAt: now,
        clientMessageId: clientMessageId,
      ),
    ];
    _summary = DailySummary(
      dateKey: _dateKey(now),
      title: '今日のまとめ',
      mood: '前向き',
      doneThings: [...?_summary?.doneThings, text],
      reflection: '会話から今日の行動を整理した。',
      tomorrowNote: '続けて1つだけ報告する。',
      generatedAt: now,
    );
    _imageHistory = [
      CharacterImageVersion(
        id: 'image-${now.microsecondsSinceEpoch}',
        title: '報告を反映した姿',
        promptExcerpt: text,
        status: CharacterImageStatus.ready,
        generatedAt: now,
      ),
      ..._imageHistory,
    ];
    _character = CharacterSnapshot(
      id: _character?.id ?? 'character-${_session.userId}',
      name: _character?.name ?? 'Mori',
      personaPrompt: _character?.personaPrompt ?? '',
      visualPromptBase: _character?.visualPromptBase ?? '',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: null,
      lastGeneratedAt: now,
      starterGreeting: _character?.starterGreeting,
    );
    _emitAll();

    await Future<void>.delayed(const Duration(milliseconds: 80));
    _messages = [
      ..._messages,
      ChatMessage(
        id: 'assistant-${now.microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        text: '受け取ったよ。明日の姿にも少し反映しておくね。',
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ];
    _emitAll();
  }

  @override
  Future<void> regenerateCharacterImage({
    String? title,
    String? reportText,
  }) async {
    final now = DateTime.now();
    final prompt = [
      '直近7日で少しずつ自信がついてきた',
      '今日は表情が少し明るい',
      if (reportText != null && reportText.trim().isNotEmpty) reportText.trim(),
    ].join(' / ');
    final imageUrl =
        'https://example.com/generated/${_session.userId}/${now.microsecondsSinceEpoch}.png';

    _imageHistory = [
      CharacterImageVersion(
        id: 'image-${now.microsecondsSinceEpoch}',
        title: title ?? '更新した姿',
        promptExcerpt: prompt,
        status: CharacterImageStatus.ready,
        generatedAt: now,
        imageUrl: imageUrl,
      ),
      ..._imageHistory,
    ];
    _character = CharacterSnapshot(
      id: _character?.id ?? 'character-${_session.userId}',
      name: _character?.name ?? 'Mori',
      personaPrompt: _character?.personaPrompt ?? '',
      visualPromptBase: _character?.visualPromptBase ?? '',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: imageUrl,
      lastGeneratedAt: now,
      starterGreeting: _character?.starterGreeting,
    );
    _emitAll();
  }

  @override
  Stream<CharacterSnapshot?> watchCharacter(String characterId) async* {
    yield _character;
    yield* _characterController.stream;
  }

  @override
  Stream<List<CharacterImageVersion>> watchImageHistory(
    String characterId,
  ) async* {
    yield List<CharacterImageVersion>.unmodifiable(_imageHistory);
    yield* _imageHistoryController.stream;
  }

  @override
  Stream<DailySummary?> watchDailySummary({
    required String userId,
    required String dateKey,
  }) async* {
    if (_summary != null && _summary!.dateKey == dateKey) {
      yield _summary;
    } else {
      yield null;
    }
    yield* _summaryController.stream.map((summary) {
      if (summary == null || summary.dateKey != dateKey) {
        return null;
      }
      return summary;
    });
  }

  @override
  Future<void> dispose() async {
    await _chatController.close();
    await _characterController.close();
    await _summaryController.close();
    await _imageHistoryController.close();
  }

  void _emitAll() {
    _chatController.add(List<ChatMessage>.unmodifiable(_messages));
    _characterController.add(_character);
    _summaryController.add(_summary);
    _imageHistoryController.add(
      List<CharacterImageVersion>.unmodifiable(_imageHistory),
    );
  }

  String _dateKey(DateTime dateTime) {
    final adjusted = dateTime.hour < 3
        ? dateTime.subtract(const Duration(days: 1))
        : dateTime;
    final month = adjusted.month.toString().padLeft(2, '0');
    final day = adjusted.day.toString().padLeft(2, '0');
    return '${adjusted.year}-$month-$day';
  }
}

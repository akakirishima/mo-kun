import 'dart:typed_data';

import 'dart:async';

import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';

class FakeAppRepository implements AppRepository {
  FakeAppRepository({
    AppSession? initialSession,
    CharacterSnapshot? initialCharacter,
    List<ChatMessage>? initialMessages,
    DailySummary? initialSummary,
    List<DailySummary>? initialSummaries,
    DailyBubble? initialDailyBubble,
    List<CharacterImageVersion>? initialImageHistory,
  }) : _session =
           initialSession ??
           const AppSession(userId: 'demo-user', needsOnboarding: true) {
    _character = initialCharacter;
    _messages = initialMessages ?? <ChatMessage>[];
    _summaries = _mergeSummaries(
      primary: initialSummary,
      additional: initialSummaries,
    );
    _dailyBubble = initialDailyBubble ?? _defaultDailyBubble();
    _imageHistory = initialImageHistory ?? <CharacterImageVersion>[];
    _emitAll();
  }

  final _chatController = StreamController<List<ChatMessage>>.broadcast();
  final _characterController = StreamController<CharacterSnapshot?>.broadcast();
  final _dailySummariesController =
      StreamController<List<DailySummary>>.broadcast();
  final _dailyBubbleController = StreamController<DailyBubble?>.broadcast();
  final _imageHistoryController =
      StreamController<List<CharacterImageVersion>>.broadcast();

  AppSession _session;
  CharacterSnapshot? _character;
  List<ChatMessage> _messages = <ChatMessage>[];
  List<DailySummary> _summaries = <DailySummary>[];
  DailyBubble? _dailyBubble;
  List<CharacterImageVersion> _imageHistory = <CharacterImageVersion>[];

  @override
  Future<AppSession> initializeSession() async => _session;

  @override
  Future<AppSession> completeOnboarding(UserProfileInput input) async {
    final now = DateTime.now();
    _character = CharacterSnapshot(
      id: 'character-${_session.userId}',
      name: input.displayName.isEmpty ? 'Self' : input.displayName,
      personaPrompt:
          'You are the user\'s reflective inner voice.',
      visualPromptBase:
          'Soft illustrated self-projection character, reflects recent self-improvement.',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: null,
      lastGeneratedAt: now,
      starterGreeting: '今日は何を残したい？',
    );
    _messages = <ChatMessage>[
      ChatMessage(
        id: 'starter',
        role: ChatRole.assistant,
        text: _character!.starterGreeting ?? '今日から一緒に進もう。',
        createdAt: now,
      ),
    ];
    _upsertSummary(
      DailySummary(
        dateKey: _dateKey(now),
        title: 'はじまりの日',
        diaryBody: '今日はプロフィールを登録して、自分を投影したキャラクターを迎えた。'
            '\n明日はまず小さな報告を1つ送れたらいいな。',
        mood: 'わくわく',
        doneThings: ['プロフィールを登録した', 'キャラクターを作った'],
        reflection: '最初の一歩を踏み出した日。',
        tomorrowNote: 'まずは小さな報告を1つ送ってみよう。',
        generatedAt: now,
      ),
    );
    _imageHistory = <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'image-initial',
        title: '最初の姿',
        promptExcerpt: input.goal,
        status: CharacterImageStatus.ready,
        generatedAt: now,
        dateKey: _dateKey(now),
      ),
    ];
    _dailyBubble = DailyBubble(
      dateKey: _dateKey(now),
      text: '今日はひとこと残すだけでいい。まずは今やることを置いていこう。',
      generatedAt: now,
    );
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
    Uint8List? imageBytes,
    String? imageMimeType,
    String? imageFilename,
  }) async {
    final now = DateTime.now();
    final hasPhoto = imageBytes != null && imageBytes.isNotEmpty;
    final photoAnalysis = hasPhoto
        ? const PhotoAnalysis(
            category: 'meal',
            summary: '食事の写真に見える。軽く食べた内容を残した可能性がある。',
            activity: '食事をした',
            food: 'ご飯',
            locationGuess: '',
            confidence: 'medium',
            needsConfirmation: false,
            confirmationPrompt: '',
            reactionHint: '食事をちゃんと残せたのはいい流れ。',
          )
        : null;
    _messages = [
      ..._messages,
      ChatMessage(
        id: clientMessageId,
        role: ChatRole.user,
        text: text,
        createdAt: now,
        clientMessageId: clientMessageId,
        inputType: hasPhoto ? ChatInputType.photo : ChatInputType.text,
        imageUrl: hasPhoto
            ? 'https://example.com/chat/${now.microsecondsSinceEpoch}.png'
            : null,
        imageAnalysis: photoAnalysis,
      ),
    ];
    final todayDateKey = _dateKey(now);
    final existingSummary = _summaryForDate(todayDateKey);
    final photoActivity = photoAnalysis?.activity;
    final summaryLine = [
      if (text.isNotEmpty) text,
      if (photoAnalysis != null && photoAnalysis.summary.isNotEmpty)
        photoAnalysis.summary,
    ].join(' / ');
    _upsertSummary(
      DailySummary(
        dateKey: todayDateKey,
        title: existingSummary == null ? '今日のまとめ' : '会話を重ねた日',
        diaryBody:
            '今日は${summaryLine.isNotEmpty ? summaryLine : '写真を1枚送った'}。'
            '\n明日はこの続きを少しでも話せたらいいな。',
        mood: '前向き',
        doneThings: [
          ...?existingSummary?.doneThings,
          if (text.isNotEmpty) text,
          if (photoActivity != null && photoActivity.isNotEmpty) photoActivity,
        ],
        reflection: '会話から今日の行動を整理した。',
        tomorrowNote: '続けて1つだけ報告する。',
        generatedAt: now,
      ),
    );
    _imageHistory = [
      CharacterImageVersion(
        id: 'image-${now.microsecondsSinceEpoch}',
        title: '報告を反映した姿',
        promptExcerpt: text,
        status: CharacterImageStatus.ready,
        generatedAt: now,
        dateKey: todayDateKey,
      ),
      ..._imageHistory,
    ];
    _character = CharacterSnapshot(
      id: _character?.id ?? 'character-${_session.userId}',
      name: _character?.name ?? 'Self',
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
        text: '受け取った。今日はひとつだけ進めば十分。',
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ];
    _emitAll();
  }

  @override
  Future<VoiceChatResult> sendVoiceMessage({
    required String threadId,
    required Uint8List audioBytes,
    required String mimeType,
    required int durationMs,
    required String clientMessageId,
  }) async {
    final now = DateTime.now();
    const transcriptText = '今日は音声で話した内容を残した';
    const assistantText = '昨日の流れは残っている。今日はひとつだけ進めてみよう。';

    _messages = [
      ..._messages,
      ChatMessage(
        id: clientMessageId,
        role: ChatRole.user,
        text: transcriptText,
        createdAt: now,
        clientMessageId: clientMessageId,
        inputType: ChatInputType.voice,
      ),
      ChatMessage(
        id: 'assistant-voice-${now.microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        text: assistantText,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ];
    _upsertSummary(
      DailySummary(
        dateKey: _dateKey(now),
        title: '声で整理した日',
        diaryBody: '今日は音声で気持ちを整理して、ひとつ先の動きを言葉にした。'
            '\n明日はその続きを短く残せたらいいな。',
        mood: '穏やか',
        doneThings: const <String>['音声で整理した'],
        reflection: '声にすると、自分の流れが少し見えやすくなった。',
        tomorrowNote: '続きをひとことだけ残す。',
        generatedAt: now,
      ),
    );
    _emitAll();

    return VoiceChatResult(
      transcriptText: transcriptText,
      assistantText: assistantText,
      audioStatus: VoiceChatAudioStatus.ready,
      assistantAudioBytes: Uint8List.fromList(const <int>[1, 2, 3]),
      assistantAudioMimeType: 'audio/mpeg',
      userMessageId: clientMessageId,
      assistantMessageId: 'assistant-voice-${now.microsecondsSinceEpoch}',
    );
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
        dateKey: _dateKey(now),
      ),
      ..._imageHistory,
    ];
    _character = CharacterSnapshot(
      id: _character?.id ?? 'character-${_session.userId}',
      name: _character?.name ?? 'Self',
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
  Stream<List<CharacterImageVersion>> watchDiaryImageHistory({
    required String characterId,
    required DateTime month,
  }) async* {
    yield _imageHistoryForMonth(month);
    yield* _imageHistoryController.stream.map(
      (_) => _imageHistoryForMonth(month),
    );
  }

  @override
  Stream<DailySummary?> watchDailySummary({
    required String userId,
    required String dateKey,
  }) async* {
    yield _summaryForDate(dateKey);
    yield* _dailySummariesController.stream.map(
        (summaries) => _findSummaryByDate(summaries, dateKey),
    );
  }

  @override
  Stream<DailyBubble?> watchDailyBubble({
    required String userId,
    required String dateKey,
  }) async* {
    yield _dailyBubble?.dateKey == dateKey ? _dailyBubble : null;
    yield* _dailyBubbleController.stream.map(
      (bubble) => bubble?.dateKey == dateKey ? bubble : null,
    );
  }

  @override
  Stream<List<DailySummary>> watchMonthlyDailySummaries({
    required String userId,
    required DateTime month,
  }) async* {
    yield _summariesForMonth(month);
    yield* _dailySummariesController.stream.map(
      (_) => _summariesForMonth(month),
    );
  }

  @override
  Future<void> dispose() async {
    await _chatController.close();
    await _characterController.close();
    await _dailySummariesController.close();
    await _dailyBubbleController.close();
    await _imageHistoryController.close();
  }

  void _emitAll() {
    _chatController.add(List<ChatMessage>.unmodifiable(_messages));
    _characterController.add(_character);
    _dailySummariesController.add(List<DailySummary>.unmodifiable(_summaries));
    _dailyBubbleController.add(_dailyBubble);
    _imageHistoryController.add(
      List<CharacterImageVersion>.unmodifiable(_imageHistory),
    );
  }

  DailyBubble _defaultDailyBubble() {
    final now = DateTime.now();
    return DailyBubble(
      dateKey: _dateKey(now),
      text: '昨日の流れでいい。今日は一歩だけ進めよう。',
      generatedAt: now,
      sourceDateKey: _dateKey(now.subtract(const Duration(days: 1))),
    );
  }

  DailySummary? _summaryForDate(String dateKey) {
    return _findSummaryByDate(_summaries, dateKey);
  }

  List<DailySummary> _summariesForMonth(DateTime month) {
    return List<DailySummary>.unmodifiable(
      _summaries.where(
        (summary) => summary.dateKey.startsWith(_monthKey(month)),
      ),
    );
  }

  List<CharacterImageVersion> _imageHistoryForMonth(DateTime month) {
    final cutoff = appDayBoundaryUtc(DateTime(month.year, month.month + 1, 1));
    final filtered =
        _imageHistory
            .where((image) => image.generatedAt.toUtc().isBefore(cutoff))
            .toList()
          ..sort(
            (left, right) => left.generatedAt.compareTo(right.generatedAt),
          );
    return List<CharacterImageVersion>.unmodifiable(filtered);
  }

  void _upsertSummary(DailySummary summary) {
    _summaries = [
      for (final existing in _summaries)
        if (existing.dateKey != summary.dateKey) existing,
      summary,
    ]..sort((left, right) => left.dateKey.compareTo(right.dateKey));
  }

  static List<DailySummary> _mergeSummaries({
    DailySummary? primary,
    List<DailySummary>? additional,
  }) {
    final merged = <DailySummary>[
      ...?additional,
      ...?(primary == null ? null : <DailySummary>[primary]),
    ];
    final deduped = <String, DailySummary>{};
    for (final summary in merged) {
      deduped[summary.dateKey] = summary;
    }
    final values = deduped.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return values;
  }

  DailySummary? _findSummaryByDate(
    Iterable<DailySummary> summaries,
    String dateKey,
  ) {
    for (final summary in summaries) {
      if (summary.dateKey == dateKey) {
        return summary;
      }
    }
    return null;
  }

  String _dateKey(DateTime dateTime) {
    return buildAppDateKeyFromDateTime(dateTime);
  }

  String _monthKey(DateTime dateTime) {
    return monthKey(dateTime);
  }
}

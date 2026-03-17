import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

FakeAppRepository buildFakeRepository() {
  final now = DateTime.now();
  final dateKey = _dateKey(now);
  final previousDateKey = _dateKey(now.subtract(const Duration(days: 1)));
  final previousMonthDate = DateTime(now.year, now.month - 1, 20, 9);
  final previousMonthDateKey = _dateKey(previousMonthDate);
  return FakeAppRepository(
    initialSession: const AppSession(
      userId: 'test-user',
      needsOnboarding: false,
      characterId: 'test-character',
      threadId: 'test-thread',
    ),
    initialCharacter: CharacterSnapshot(
      id: 'test-character',
      name: 'Mori',
      personaPrompt: 'やわらかく励ます相棒。',
      visualPromptBase: '会話内容に応じて見た目が少し変わる相棒。',
      imageStatus: CharacterImageStatus.ready,
      lastGeneratedAt: now,
      starterGreeting: '今日も会えて嬉しいな。\n一緒にお話ししよ！',
    ),
    initialMessages: <ChatMessage>[
      ChatMessage(
        id: 'assistant-1',
        role: ChatRole.assistant,
        text: 'おはよう。昨日の積み上げ、ちゃんと覚えてるよ。',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
    ],
    initialSummary: DailySummary(
      dateKey: dateKey,
      title: '小さく前進した日',
      mood: '前向き',
      doneThings: const <String>['報告を1つ送った', 'UIを整えた'],
      reflection: 'やることを言葉にすると次の動きが見えた。',
      tomorrowNote: '朝に短く報告して流れを作る。',
      generatedAt: now,
    ),
    initialSummaries: <DailySummary>[
      DailySummary(
        dateKey: previousDateKey,
        title: '言葉を整えた日',
        mood: '穏やか',
        doneThings: const <String>['会話を読み返した', '明日の段取りを書いた'],
        reflection: '短い記録でも見返すと流れがつながった。',
        tomorrowNote: '次はやったことを一言で残す。',
        generatedAt: now.subtract(const Duration(days: 1)),
      ),
      DailySummary(
        dateKey: previousMonthDateKey,
        title: '先月の積み上げ',
        mood: '静かな達成',
        doneThings: const <String>['習慣を少し続けた'],
        reflection: '無理なく続いたことが形になってきた。',
        tomorrowNote: '次の月も同じ速度で進める。',
        generatedAt: previousMonthDate,
      ),
    ],
    initialImageHistory: <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'history-1',
        title: '昨日の報告を反映した姿',
        promptExcerpt: '筋トレを頑張ったので少したくましい印象',
        status: CharacterImageStatus.ready,
        generatedAt: now,
        imageUrl: 'https://example.com/today.png',
        dateKey: dateKey,
      ),
      CharacterImageVersion(
        id: 'history-2',
        title: '先月の積み上がりを反映した姿',
        promptExcerpt: '静かに積み上がってきた印象',
        status: CharacterImageStatus.ready,
        generatedAt: previousMonthDate,
        imageUrl: 'https://example.com/last-month.png',
        dateKey: previousMonthDateKey,
      ),
    ],
  );
}

String _dateKey(DateTime dateTime) {
  return buildAppDateKeyFromDateTime(dateTime);
}

Widget wrapWithTestApp({
  required Widget child,
  FakeAppRepository? repository,
  List<Override> overrides = const <Override>[],
}) {
  final appearanceController = AppearanceController();
  final repo = repository ?? buildFakeRepository();

  return ProviderScope(
    overrides: [appRepositoryProvider.overrideWithValue(repo), ...overrides],
    child: AppearanceScope(
      controller: appearanceController,
      child: MaterialApp(
        theme: AppTheme.light(appearanceController.palette),
        home: Scaffold(body: child),
      ),
    ),
  );
}

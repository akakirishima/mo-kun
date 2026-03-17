import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

FakeAppRepository buildFakeRepository() {
  final now = DateTime(2026, 3, 16, 10, 0);
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
      dateKey: '2026-03-16',
      title: '小さく前進した日',
      mood: '前向き',
      doneThings: const <String>['報告を1つ送った', 'UIを整えた'],
      reflection: 'やることを言葉にすると次の動きが見えた。',
      tomorrowNote: '朝に短く報告して流れを作る。',
      generatedAt: now,
    ),
    initialImageHistory: <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'history-1',
        title: '昨日の報告を反映した姿',
        promptExcerpt: '筋トレを頑張ったので少したくましい印象',
        status: CharacterImageStatus.ready,
        generatedAt: now,
      ),
    ],
  );
}

Widget wrapWithTestApp({required Widget child, FakeAppRepository? repository}) {
  final appearanceController = AppearanceController();
  final repo = repository ?? buildFakeRepository();

  return ProviderScope(
    overrides: [appRepositoryProvider.overrideWithValue(repo)],
    child: AppearanceScope(
      controller: appearanceController,
      child: MaterialApp(
        theme: AppTheme.light(appearanceController.palette),
        home: Scaffold(body: child),
      ),
    ),
  );
}

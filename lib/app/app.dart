import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/bootstrap/app_bootstrap_screen.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.appearanceController, this.repository});

  final AppRepository? repository;
  final AppearanceController? appearanceController;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppearanceController _appearanceController;
  late final AppRepository _repository;

  @override
  void initState() {
    super.initState();
    _appearanceController =
        widget.appearanceController ?? AppearanceController();
    _repository = widget.repository ?? _buildPreviewRepository();
    if (widget.appearanceController == null) {
      _appearanceController.load();
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearanceController,
      builder: (context, _) {
        return AppearanceScope(
          controller: _appearanceController,
          child: ProviderScope(
            overrides: [appRepositoryProvider.overrideWithValue(_repository)],
            child: MaterialApp(
              title: 'GDGoC 2026 Prototype',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(_appearanceController.palette),
              home: const AppBootstrapScreen(),
            ),
          ),
        );
      },
    );
  }
}

AppRepository _buildPreviewRepository() {
  final now = DateTime.now();
  return FakeAppRepository(
    initialSession: const AppSession(
      userId: 'preview-user',
      needsOnboarding: false,
      characterId: 'preview-character',
      threadId: 'preview-thread',
    ),
    initialCharacter: CharacterSnapshot(
      id: 'preview-character',
      name: 'Mori',
      personaPrompt: 'やわらかく励ます相棒。',
      visualPromptBase: '昨日の報告を少しずつ見た目に反映する相棒。',
      imageStatus: CharacterImageStatus.ready,
      latestImageUrl: null,
      lastGeneratedAt: now.subtract(const Duration(hours: 7)),
      starterGreeting: '今日も会えて嬉しいな。\n一緒にお話ししよ！',
    ),
    initialMessages: <ChatMessage>[
      ChatMessage(
        id: 'assistant-preview-1',
        role: ChatRole.assistant,
        text: 'おはよう。昨日の積み上げ、ちゃんと覚えてるよ。',
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
    ],
    initialSummary: DailySummary(
      dateKey: _dateKey(now),
      title: '小さく前進した日',
      mood: '前向き',
      doneThings: const <String>['UI を調整した', '報告を1つ送った'],
      reflection: '少しずつでも続けると、翌朝の見え方が変わる。',
      tomorrowNote: '起きたらまず一言だけでも報告する。',
      generatedAt: now.subtract(const Duration(hours: 6)),
    ),
    initialImageHistory: <CharacterImageVersion>[
      CharacterImageVersion(
        id: 'preview-image-1',
        title: '昨日の報告を反映した姿',
        promptExcerpt: '筋トレを頑張ったので少し引き締まった体つき',
        status: CharacterImageStatus.ready,
        generatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ],
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

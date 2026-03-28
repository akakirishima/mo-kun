import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_shell.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/onboarding/presentation/onboarding_screen.dart';

class AppBootstrapScreen extends ConsumerWidget {
  const AppBootstrapScreen({
    super.key,
    this.enableDiaryCoverTurnTeaser = true,
  });

  final bool enableDiaryCoverTurnTeaser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    return sessionAsync.when(
      data: (session) {
        if (!session.needsOnboarding) {
          final controller = AppearanceScope.controllerOf(context);
          final remotePreset =
              ref.watch(appearancePreferenceProvider(session.userId)).valueOrNull;
          if (remotePreset != null && remotePreset != controller.preset) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(
                controller.selectPreset(remotePreset, persistLocal: true),
              );
            });
          }
        }
        if (session.needsOnboarding) {
          return const OnboardingScreen();
        }
        return AppShell(
          enableDiaryCoverTurnTeaser: enableDiaryCoverTurnTeaser,
        );
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('初期化に失敗しました'),
                  const SizedBox(height: 12),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(sessionProvider),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

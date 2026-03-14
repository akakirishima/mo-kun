import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_quote_card.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onStartCallTap,
    required this.transcriptText,
    required this.onSettingsTap,
  });

  final VoidCallback onStartCallTap;
  final String transcriptText;
  final VoidCallback onSettingsTap;
  static const _contentBottomPadding =
      GlassBottomDock.reservedBottomSpacing + 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).home;

    return DecoratedBox(
      key: const ValueKey<String>('home-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.pageTop, palette.pageBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('home-screen-scroll'),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, _contentBottomPadding),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 0, 10),
              child: Row(
                children: [
                  Text(
                    'Mori room',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.headerText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey<String>('home-settings-button'),
                    onPressed: onSettingsTap,
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: '設定',
                    color: palette.settingsIcon,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: palette.panelFill,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: palette.panelOutline, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: palette.panelShadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: palette.panelGlow, width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.panelGradientTop,
                      palette.panelGradientBottom,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeQuoteCard(transcriptText: transcriptText),
                    const SizedBox(height: 24),
                    const HomeRoomStage(
                      key: ValueKey<String>('home-room-stage'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('home-talk-button'),
                        onPressed: onStartCallTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.talkButtonFill,
                          foregroundColor: palette.talkButtonText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: palette.talkButtonOutline,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.mic_none_rounded, size: 24),
                        label: const Text('話しかける'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

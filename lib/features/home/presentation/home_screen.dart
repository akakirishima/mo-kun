import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_background_theme.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_voice.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';
import 'package:nes_ui/nes_ui.dart';

enum HomeOverlayMode { none, voice, photo, chat }

class _StageMedia {
  const _StageMedia({this.videoUrl, this.imageUrl});

  final String? videoUrl;
  final String? imageUrl;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    required this.onDiaryTap,
    this.onOverlayModeChanged,
    this.initialBubbleMessage = '昨日の流れは残っている。今日は一つだけ進めよう、自分。',
    this.liveVoiceController,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onDiaryTap;
  final ValueChanged<HomeOverlayMode>? onOverlayModeChanged;
  final String initialBubbleMessage;
  final LiveVoiceSessionController? liveVoiceController;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _bottomSafeSpacing = 36.0;

  LiveVoiceSessionController? _liveVoiceController;
  HomeOverlayMode _overlayMode = HomeOverlayMode.none;
  String? _voiceBubbleText;
  LiveVoiceUiState _liveVoiceState = LiveVoiceUiState.disconnected;

  @override
  void initState() {
    super.initState();
    if (widget.liveVoiceController != null) {
      _liveVoiceController = widget.liveVoiceController;
      _liveVoiceState = widget.liveVoiceController!.state;
      widget.liveVoiceController!.listenable.addListener(
        _handleLiveVoiceChanged,
      );
    }
  }

  @override
  void dispose() {
    final controller = _liveVoiceController;
    if (controller != null) {
      controller.listenable.removeListener(_handleLiveVoiceChanged);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  LiveVoiceSessionController _ensureLiveVoiceController() {
    final existing = _liveVoiceController;
    if (existing != null) {
      return existing;
    }
    final created =
        widget.liveVoiceController ?? DeviceLiveVoiceSessionController();
    _liveVoiceController = created;
    _liveVoiceState = created.state;
    created.listenable.addListener(_handleLiveVoiceChanged);
    return created;
  }

  void _handleLiveVoiceChanged() {
    if (!mounted) {
      return;
    }
    final controller = _liveVoiceController;
    if (controller == null) {
      return;
    }
    setState(() {
      _liveVoiceState = controller.state;
      _voiceBubbleText =
          _liveVoiceState.assistantText ??
          _liveVoiceState.partialAssistantText ??
          _voiceBubbleText;
    });
  }

  Future<void> _setOverlayMode(HomeOverlayMode mode) async {
    if (_overlayMode == mode) {
      return;
    }
    if (_overlayMode == HomeOverlayMode.voice &&
        mode != HomeOverlayMode.voice) {
      await _resetVoiceMode();
    }
    if (_overlayMode != HomeOverlayMode.voice &&
        mode == HomeOverlayMode.voice) {
      final session = await ref.read(sessionProvider.future);
      final threadId = session.threadId;
      if (threadId == null) {
        return;
      }
      await _ensureLiveVoiceController().connect(threadId: threadId);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _overlayMode = mode;
    });
    widget.onOverlayModeChanged?.call(mode);
  }

  Future<void> _handleVoicePrimaryTap() async {
    switch (_liveVoiceState.phase) {
      case LiveVoicePhase.connecting:
      case LiveVoicePhase.reconnecting:
        return;
      case LiveVoicePhase.disconnected:
        final session = await ref.read(sessionProvider.future);
        final threadId = session.threadId;
        if (threadId == null) {
          return;
        }
        await _ensureLiveVoiceController().connect(threadId: threadId);
        return;
      case LiveVoicePhase.listening:
      case LiveVoicePhase.speaking:
      case LiveVoicePhase.error:
        await _ensureLiveVoiceController().toggleMicrophone();
        return;
    }
  }

  Future<void> _resetVoiceMode() async {
    await _liveVoiceController?.disconnect();
    if (!mounted) {
      return;
    }
    setState(() {
      _liveVoiceState = LiveVoiceUiState.disconnected;
      _voiceBubbleText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    final session = ref.watch(sessionProvider).valueOrNull;
    final dailyBubble = session == null
        ? null
        : ref.watch(dailyBubbleProvider(session)).valueOrNull;
    final characterId = session?.characterId;
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    final stageMedia = _StageMedia(
      videoUrl: character?.latestSquareVideoUrl,
      imageUrl: character?.posterImageUrl ?? character?.latestImageUrl,
    );
    final resolvedCharacterVideoUrl = ref.watch(
      resolvedImageUrlProvider(stageMedia.videoUrl),
    );
    final resolvedCharacterImageUrl = ref.watch(
      resolvedImageUrlProvider(stageMedia.imageUrl),
    );
    final hasRawCharacterVideoUrl =
        stageMedia.videoUrl != null && stageMedia.videoUrl!.isNotEmpty;
    final rawCharacterImageUrl = stageMedia.imageUrl;
    final hasRawCharacterImageUrl =
        rawCharacterImageUrl != null && rawCharacterImageUrl.isNotEmpty;
    final hasResolvedVideoUrl =
        (resolvedCharacterVideoUrl.valueOrNull ?? '').isNotEmpty;
    final hasResolvedImageUrl =
        (resolvedCharacterImageUrl.valueOrNull ?? '').isNotEmpty;
    final isMediaLoading =
        (hasRawCharacterVideoUrl && resolvedCharacterVideoUrl.isLoading) ||
        (hasRawCharacterImageUrl && resolvedCharacterImageUrl.isLoading);
    final stageState = hasResolvedVideoUrl || hasResolvedImageUrl
        ? HomeRoomStageState.ready
        : isMediaLoading
        ? HomeRoomStageState.loading
        : (!hasRawCharacterVideoUrl && !hasRawCharacterImageUrl)
        ? HomeRoomStageState.empty
        : HomeRoomStageState.error;
    final stageMessage = switch (stageState) {
      HomeRoomStageState.loading => '画像を準備しています',
      HomeRoomStageState.empty => 'まだ画像がありません',
      HomeRoomStageState.error => '通信に失敗しました',
      HomeRoomStageState.ready => '',
    };
    final bubbleText =
        _voiceBubbleText ??
        dailyBubble?.text ??
        character?.starterGreeting ??
        widget.initialBubbleMessage;
    final backgroundPreference = session == null
        ? null
        : ref
              .watch(homeBackgroundPreferenceProvider(session.userId))
              .valueOrNull;
    final backgroundTheme = HomeBackgroundTheme.resolve(
      backgroundPreference?.themeId,
    );
    final customBackgroundUrl = backgroundPreference?.customImageUrl;

    return Stack(
      key: const ValueKey<String>('home-background'),
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: -GlassBottomDock.reservedBottomSpacing,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.pageTop, palette.pageBottom],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      (customBackgroundUrl != null &&
                          customBackgroundUrl.isNotEmpty)
                      ? Image.network(
                          customBackgroundUrl,
                          key: const ValueKey<String>('home-background-image'),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, _, _) => Image.asset(
                            backgroundTheme.backgroundAssetPath,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        )
                      : Image.asset(
                          backgroundTheme.backgroundAssetPath,
                          key: const ValueKey<String>('home-background-image'),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxStageWidth = math.max(constraints.maxWidth - 12, 0.0);
              final stageHeightFactor = _overlayMode == HomeOverlayMode.voice
                  ? 0.34
                  : 0.52;
              final minStageSize = _overlayMode == HomeOverlayMode.voice
                  ? 168.0
                  : 220.0;
              final stageSize = math.min(
                maxStageWidth,
                math.max(
                  constraints.maxHeight * stageHeightFactor,
                  minStageSize,
                ),
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DailyBubbleCard(
                      text: bubbleText,
                      titleColor: palette.transcriptTitle,
                      textColor: palette.transcriptText,
                      outerBorder: palette.transcriptOuterBorder,
                      innerBorder: palette.transcriptInnerBorder,
                      fillColor: palette.transcriptFill.withValues(alpha: 0.9),
                      shadowColor: palette.transcriptShadow,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: _StageFrame(
                          size: stageSize,
                          child: HomeRoomStage(
                            videoUrl: resolvedCharacterVideoUrl.valueOrNull,
                            imageUrl: resolvedCharacterImageUrl.valueOrNull,
                            state: stageState,
                            message: stageMessage,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _HomePrimaryButton(
                      buttonKey: const ValueKey<String>('home-talk-button'),
                      label: _overlayMode == HomeOverlayMode.voice
                          ? '音声パネルを閉じる'
                          : '話しかける',
                      fillColor: palette.talkButtonFill,
                      borderColor: palette.talkButtonOutline,
                      textColor: palette.talkButtonText,
                      onPressed: () {
                        final nextMode = _overlayMode == HomeOverlayMode.voice
                            ? HomeOverlayMode.none
                            : HomeOverlayMode.voice;
                        unawaited(_setOverlayMode(nextMode));
                      },
                    ),
                    const SizedBox(height: _bottomSafeSpacing),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 140, 18, 150),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _overlayMode == HomeOverlayMode.voice
                    ? SingleChildScrollView(
                        key: const ValueKey<String>('home-voice-panel'),
                        child: _VoicePanel(
                          liveState: _liveVoiceState,
                          onClose: () {
                            unawaited(_setOverlayMode(HomeOverlayMode.none));
                          },
                          onPrimaryTap: _handleVoicePrimaryTap,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyBubbleCard extends StatelessWidget {
  const _DailyBubbleCard({
    required this.text,
    required this.titleColor,
    required this.textColor,
    required this.outerBorder,
    required this.innerBorder,
    required this.fillColor,
    required this.shadowColor,
  });

  final String text;
  final Color titleColor;
  final Color textColor;
  final Color outerBorder;
  final Color innerBorder;
  final Color fillColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-daily-bubble'),
      decoration: BoxDecoration(
        color: outerBorder.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.46),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, right: 4, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor.withValues(alpha: 0.96),
            border: Border.all(
              color: innerBorder.withValues(alpha: 0.76),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PixelBadge(
                      label: '今日の一言',
                      fillColor: const Color(0xFFE7A64C),
                      borderColor: const Color(0xFF4B2D1E),
                      textColor: const Color(0xFF2C170C),
                    ),
                    const Spacer(),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: outerBorder.withValues(alpha: 0.92),
                        border: Border.all(
                          color: const Color(0xFF4B2D1E),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  color: outerBorder.withValues(alpha: 0.82),
                ),
                const SizedBox(height: 14),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageFrame extends StatelessWidget {
  const _StageFrame({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}

class _HomePrimaryButton extends StatelessWidget {
  const _HomePrimaryButton({
    required this.buttonKey,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _RoundedNesButton(
      buttonKey: buttonKey,
      label: label,
      fillColor: fillColor,
      borderColor: borderColor,
      textColor: textColor,
      icon: Icons.mic_none_rounded,
      onPressed: onPressed,
      height: 62,
      radius: 20,
      shadowColor: const Color(0xAA6A371C),
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _VoicePanel extends StatelessWidget {
  const _VoicePanel({
    required this.liveState,
    required this.onClose,
    required this.onPrimaryTap,
  });

  final LiveVoiceUiState liveState;
  final VoidCallback onClose;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (liveState.phase) {
      LiveVoicePhase.connecting => '接続中',
      LiveVoicePhase.reconnecting => '再接続中',
      LiveVoicePhase.speaking =>
        liveState.microphoneEnabled ? 'マイクをオフ' : '割り込んで話す',
      LiveVoicePhase.error =>
        liveState.microphoneEnabled ? 'マイクをオフ' : 'もう一度つなぐ',
      LiveVoicePhase.disconnected =>
        liveState.microphoneEnabled ? 'マイクをオフ' : '接続する',
      LiveVoicePhase.listening =>
        liveState.microphoneEnabled ? 'マイクをオフ' : 'マイクをオン',
    };
    final helper = switch (liveState.phase) {
      LiveVoicePhase.connecting => 'Gemini Live に接続しています',
      LiveVoicePhase.reconnecting => '接続が切れたため再接続しています',
      LiveVoicePhase.speaking => '相手の音声を逐次再生しています',
      LiveVoicePhase.error => liveState.errorText ?? 'Live セッションでエラーが発生しました',
      LiveVoicePhase.disconnected => '接続後にマイクをオンにして会話します',
      LiveVoicePhase.listening =>
        liveState.microphoneEnabled ? 'マイク入力を逐次送信しています' : 'マイクをオンにすると会話を始めます',
    };

    return _RoundedNesPanel(
      backgroundColor: const Color(0xFFFFF4DD).withValues(alpha: 0.97),
      borderColor: const Color(0xFFFFE8A7),
      innerBorderColor: const Color(0xFFE7B061),
      shadowColor: const Color(0x553F1E12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PixelTag(
                label: 'VOICE',
                fillColor: const Color(0xFFF3D8B3),
                borderColor: const Color(0xFF7A4A35),
                textColor: const Color(0xFF7A4A35),
              ),
              const Spacer(),
              _PixelIconButton(
                buttonKey: const ValueKey<String>('home-voice-close-button'),
                icon: Icons.close_rounded,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A5A49),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _RoundedNesButton(
            buttonKey: const ValueKey<String>('home-voice-primary-button'),
            onPressed:
                (liveState.phase == LiveVoicePhase.connecting ||
                    liveState.phase == LiveVoicePhase.reconnecting)
                ? null
                : onPrimaryTap,
            label: label,
            icon: switch (liveState.phase) {
              LiveVoicePhase.connecting => Icons.hourglass_top_rounded,
              LiveVoicePhase.reconnecting => Icons.refresh_rounded,
              LiveVoicePhase.speaking =>
                liveState.microphoneEnabled
                    ? Icons.mic_off_rounded
                    : Icons.record_voice_over_rounded,
              LiveVoicePhase.error => Icons.refresh_rounded,
              LiveVoicePhase.disconnected =>
                liveState.microphoneEnabled
                    ? Icons.mic_off_rounded
                    : Icons.link_rounded,
              LiveVoicePhase.listening =>
                liveState.microphoneEnabled
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
            },
            fillColor: const Color(0xFFE59B74),
            borderColor: const Color(0xFF7A4A35),
            textColor: Colors.white,
            height: 52,
            radius: 18,
            shadowColor: const Color(0xAA7A4A35),
            textStyle: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (liveState.partialTranscriptText != null &&
              liveState.partialTranscriptText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'あなたの声(途中)',
              body: liveState.partialTranscriptText!,
            ),
          ],
          if (liveState.transcriptText != null &&
              liveState.transcriptText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(title: 'あなたの声', body: liveState.transcriptText!),
          ],
          if (liveState.partialAssistantText != null &&
              liveState.partialAssistantText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoCard(title: '返答(途中)', body: liveState.partialAssistantText!),
          ],
          if (liveState.assistantText != null &&
              liveState.assistantText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoCard(title: '返答', body: liveState.assistantText!),
          ],
          if (liveState.model != null && liveState.model!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              liveState.fallbackUsed
                  ? 'model: ${liveState.model} (fallback)'
                  : 'model: ${liveState.model}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A5A49),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (liveState.errorText != null &&
              liveState.errorText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              liveState.errorText!,
              key: const ValueKey<String>('home-voice-error-text'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8A425E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _RoundedNesPanel(
      backgroundColor: const Color(0xFFFFF7EC),
      borderColor: const Color(0xFFE4BA95),
      innerBorderColor: const Color(0xFFF0D4AF),
      shadowColor: const Color(0x333F1E12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PixelTag(
            label: title,
            fillColor: const Color(0xFFF8D5B8),
            borderColor: const Color(0xFF8B5B4A),
            textColor: const Color(0xFF8B5B4A),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF68493C),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedNesPanel extends StatelessWidget {
  const _RoundedNesPanel({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.innerBorderColor,
    required this.shadowColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color innerBorderColor;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 6))],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: innerBorderColor, width: 2),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: child,
      ),
    );
  }
}

class _RoundedNesButton extends StatelessWidget {
  const _RoundedNesButton({
    required this.buttonKey,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.onPressed,
    required this.height,
    required this.radius,
    required this.shadowColor,
    this.textStyle,
  });

  final Key buttonKey;
  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final Color shadowColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.65 : 1,
      child: Semantics(
        button: true,
        child: NesPressable(
          key: buttonKey,
          disabled: onPressed == null,
          onPress: onPressed,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(color: shadowColor, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 10),
                Text(
                  label,
                  style:
                      textStyle ??
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelTag extends StatelessWidget {
  const _PixelTag({
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PixelBadge extends StatelessWidget {
  const _PixelBadge({
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66331A0F), offset: Offset(2, 2)),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  const _PixelIconButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NesPressable(
      key: buttonKey,
      onPress: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF7E7D0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A4A35), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xAA7A4A35), offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF7A4A35)),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
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
      final controller = _ensureLiveVoiceController();
      await controller.connect(threadId: threadId);
      await controller.toggleMicrophone();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _overlayMode = mode;
    });
    widget.onOverlayModeChanged?.call(mode);
  }

  Future<void> _handleVoiceMicrophoneTap() async {
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
        final controller = _ensureLiveVoiceController();
        await controller.connect(threadId: threadId);
        await controller.toggleMicrophone();
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

    Widget buildStageWidget() {
      return HomeRoomStage(
        videoUrl: resolvedCharacterVideoUrl.valueOrNull,
        imageUrl: resolvedCharacterImageUrl.valueOrNull,
        state: stageState,
        message: stageMessage,
      );
    }

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
              final stageSize = math.min(
                maxStageWidth,
                math.max(constraints.maxHeight * 0.52, 220.0),
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
                          child: buildStageWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _HomePrimaryButton(
                      buttonKey: const ValueKey<String>('home-talk-button'),
                      label: _overlayMode == HomeOverlayMode.voice
                          ? '通話画面を閉じる'
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
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _overlayMode != HomeOverlayMode.voice,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _overlayMode == HomeOverlayMode.voice
                  ? _VoiceCallOverlay(
                      key: const ValueKey<String>('home-voice-overlay'),
                      liveState: _liveVoiceState,
                      stage: buildStageWidget(),
                      onEndCall: () {
                        unawaited(_setOverlayMode(HomeOverlayMode.none));
                      },
                      onMicrophoneTap: _handleVoiceMicrophoneTap,
                    )
                  : const SizedBox.shrink(),
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
        color: fillColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: innerBorder.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日のメッセージ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
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

class _VoiceCallOverlay extends StatefulWidget {
  const _VoiceCallOverlay({
    super.key,
    required this.liveState,
    required this.stage,
    required this.onEndCall,
    required this.onMicrophoneTap,
  });

  final LiveVoiceUiState liveState;
  final Widget stage;
  final VoidCallback onEndCall;
  final VoidCallback onMicrophoneTap;

  @override
  State<_VoiceCallOverlay> createState() => _VoiceCallOverlayState();
}

class _VoiceCallOverlayState extends State<_VoiceCallOverlay> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _VoiceCallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveState.transcriptEntries.length !=
            widget.liveState.transcriptEntries.length ||
        oldWidget.liveState.partialAssistantText !=
            widget.liveState.partialAssistantText ||
        oldWidget.liveState.partialTranscriptText !=
            widget.liveState.partialTranscriptText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.liveState.transcriptEntries;

    return Material(
      color: Colors.black.withValues(alpha: 0.20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: 1.12,
              child: Opacity(opacity: 0.94, child: widget.stage),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x88592727),
                    Color(0x66461F2B),
                    Color(0x88551D29),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: 520,
                        child: ListView.builder(
                          key: const ValueKey<String>(
                            'home-voice-transcript-list',
                          ),
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: 4,
                            right: 4,
                            top: 24,
                            bottom: 20,
                          ),
                          itemCount: math.max(entries.length, 1),
                          itemBuilder: (context, index) {
                            if (entries.isEmpty) {
                              return const _VoiceEmptyState();
                            }
                            return _VoiceTranscriptBubble(
                              entry: entries[index],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (widget.liveState.errorText != null &&
                      widget.liveState.errorText!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PixelPanel(
                      fillColor: const Color(0xFFE7C0BA),
                      outerBorderColor: const Color(0xFF6A2E2E),
                      innerBorderColor: const Color(0xFFB55A57),
                      child: Text(
                        widget.liveState.errorText!,
                        key: const ValueKey<String>('home-voice-error-text'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF491919),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _VoiceInputWaveform(
                    levels: widget.liveState.inputLevelHistory,
                    microphoneEnabled: widget.liveState.microphoneEnabled,
                    inputStreamingSuspended:
                        widget.liveState.inputStreamingSuspended,
                  ),
                  const SizedBox(height: 16),
                  _VoiceControlDock(
                    liveState: widget.liveState,
                    onEndCall: widget.onEndCall,
                    onMicrophoneTap: widget.onMicrophoneTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceInputWaveform extends StatelessWidget {
  const _VoiceInputWaveform({
    required this.levels,
    required this.microphoneEnabled,
    required this.inputStreamingSuspended,
  });

  final List<double> levels;
  final bool microphoneEnabled;
  final bool inputStreamingSuspended;

  @override
  Widget build(BuildContext context) {
    const sampleCount = 20;
    final baseline = microphoneEnabled ? 0.08 : 0.04;
    final recentLevels = levels.length <= sampleCount
        ? levels
        : levels.sublist(levels.length - sampleCount);
    final samples = levels.isEmpty
        ? List<double>.filled(sampleCount, baseline)
        : <double>[
            ...List<double>.filled(
              math.max(sampleCount - recentLevels.length, 0),
              baseline,
            ),
            ...recentLevels,
          ];

    return _PixelPanel(
      key: const ValueKey<String>('home-voice-waveform'),
      fillColor: const Color(0xFFE8DDC4),
      outerBorderColor: const Color(0xFF6A4A2A),
      innerBorderColor: const Color(0xFFA97A47),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'MIC INPUT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF432513),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '音声入力を表示中',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A4A2A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 3, color: const Color(0xFF7A5631)),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < samples.length; index += 1)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == samples.length - 1 ? 0 : 4,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
                          height: 8 + (36 * samples[index]),
                          decoration: const BoxDecoration(
                            color: Color(0xFF63D7C4),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color(0xFF3A544D),
                                width: 2,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFB9FFF1),
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceControlDock extends StatelessWidget {
  const _VoiceControlDock({
    required this.liveState,
    required this.onEndCall,
    required this.onMicrophoneTap,
  });

  final LiveVoiceUiState liveState;
  final VoidCallback onEndCall;
  final VoidCallback onMicrophoneTap;

  @override
  Widget build(BuildContext context) {
    final micLabel = switch (liveState.phase) {
      LiveVoicePhase.connecting => '接続中',
      LiveVoicePhase.reconnecting => '再接続中',
      LiveVoicePhase.error => liveState.microphoneEnabled ? 'マイクON' : '再接続',
      LiveVoicePhase.disconnected =>
        liveState.microphoneEnabled ? 'マイクON' : '接続する',
      LiveVoicePhase.listening =>
        liveState.microphoneEnabled ? 'マイクON' : 'マイクOFF',
      LiveVoicePhase.speaking => liveState.microphoneEnabled ? '会話中' : 'マイクOFF',
    };

    final micIcon = switch (liveState.phase) {
      LiveVoicePhase.connecting => Icons.hourglass_top_rounded,
      LiveVoicePhase.reconnecting => Icons.refresh_rounded,
      LiveVoicePhase.error => Icons.refresh_rounded,
      LiveVoicePhase.disconnected => Icons.link_rounded,
      LiveVoicePhase.listening =>
        liveState.microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
      LiveVoicePhase.speaking =>
        liveState.microphoneEnabled
            ? Icons.graphic_eq_rounded
            : Icons.mic_off_rounded,
    };

    return _PixelPanel(
      key: const ValueKey<String>('home-voice-control-dock'),
      fillColor: const Color(0xFFE4D4BC),
      outerBorderColor: const Color(0xFF6A4A2A),
      innerBorderColor: const Color(0xFFA97A47),
      child: Row(
        children: [
          Expanded(
            child: Text(
              liveState.microphoneEnabled
                  ? 'マイクは通話終了まで維持されます'
                  : '通話中のマイクを切り替えられます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4A2E1D),
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _VoiceRoundButton(
            buttonKey: const ValueKey<String>('home-voice-primary-button'),
            icon: micIcon,
            label: micLabel,
            fillColor: const Color(0xAA69CDB1),
            borderColor: const Color(0xFFE7FFF8),
            onPressed:
                (liveState.phase == LiveVoicePhase.connecting ||
                    liveState.phase == LiveVoicePhase.reconnecting)
                ? null
                : onMicrophoneTap,
          ),
          const SizedBox(width: 12),
          _VoiceRoundButton(
            buttonKey: const ValueKey<String>('home-voice-close-button'),
            icon: Icons.call_end_rounded,
            label: '通話終了',
            fillColor: const Color(0xCCE16060),
            borderColor: const Color(0xFFFFE2E2),
            onPressed: onEndCall,
          ),
        ],
      ),
    );
  }
}

class _VoiceRoundButton extends StatelessWidget {
  const _VoiceRoundButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final Color fillColor;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.58 : 1,
      child: NesPressable(
        key: buttonKey,
        disabled: onPressed == null,
        onPress: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 104),
          decoration: BoxDecoration(
            color: const Color(0xFF4C301D),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(3, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              color: borderColor,
              padding: const EdgeInsets.all(3),
              child: Container(
                color: fillColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceTranscriptBubble extends StatelessWidget {
  const _VoiceTranscriptBubble({required this.entry});

  final LiveVoiceTranscriptEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.speaker == LiveVoiceSpeaker.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser
        ? const Color(0xFF77CDB1)
        : const Color(0xFFF5E8CF);
    final outerBorderColor = isUser
        ? const Color(0xFF2E6658)
        : const Color(0xFF6A4A2A);
    final innerBorderColor = isUser
        ? const Color(0xFFB9FFF1)
        : const Color(0xFFA97A47);
    final textColor = isUser ? const Color(0xFF14332B) : const Color(0xFF352218);
    final label = isUser ? 'あなた' : 'コトモ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: isUser ? 0 : 8,
                  right: isUser ? 8 : 0,
                  bottom: 4,
                ),
                child: Text(
                  entry.isPartial ? '$label • 入力中' : label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFFDF2D0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Opacity(
                opacity: entry.isPartial ? 0.82 : 1,
                child: _PixelPanel(
                  fillColor: bubbleColor,
                  outerBorderColor: outerBorderColor,
                  innerBorderColor: innerBorderColor,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Text(
                    entry.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      height: 1.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceEmptyState extends StatelessWidget {
  const _VoiceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: _PixelPanel(
          fillColor: const Color(0xFFF5E8CF),
          outerBorderColor: const Color(0xFF6A4A2A),
          innerBorderColor: const Color(0xFFA97A47),
          child: Text(
            'ここに会話の字幕が流れます',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF3F2414),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelPanel extends StatelessWidget {
  const _PixelPanel({
    super.key,
    required this.child,
    required this.fillColor,
    required this.outerBorderColor,
    required this.innerBorderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final Widget child;
  final Color fillColor;
  final Color outerBorderColor;
  final Color innerBorderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: outerBorderColor,
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), offset: Offset(3, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: NesContainer(
          backgroundColor: fillColor,
          borderColor: innerBorderColor,
          padding: padding,
          painterBuilder: NesContainerSquareCornerPainter.new,
          child: child,
        ),
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

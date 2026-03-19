import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_voice.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';
import 'package:image_picker/image_picker.dart';

typedef HomeChatImagePicker = Future<XFile?> Function(ImageSource source);
typedef HomeChatLostDataRetriever = Future<LostDataResponse> Function();

enum HomeOverlayMode { none, voice, photo, chat }

enum HomeVoiceState { idle, recording, uploading, playing, error }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    this.onOverlayModeChanged,
    this.initialBubbleMessage = '昨日の流れは残っている。今日は一つだけ進めよう、自分。',
    this.pickImage,
    this.retrieveLostData,
    this.voiceRecorder,
    this.voicePlayer,
  });

  final VoidCallback onSettingsTap;
  final ValueChanged<HomeOverlayMode>? onOverlayModeChanged;
  final String initialBubbleMessage;
  final HomeChatImagePicker? pickImage;
  final HomeChatLostDataRetriever? retrieveLostData;
  final VoiceRecorderController? voiceRecorder;
  final VoicePlayerController? voicePlayer;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _horizontalPadding = 18.0;
  static const _actionBarHeight = 92.0;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _messageScrollController;
  late final VoiceRecorderController _voiceRecorder;
  late final VoicePlayerController _voicePlayer;
  final ImagePicker _imagePicker = ImagePicker();
  final List<_HomeChatMessage> _localMessages = <_HomeChatMessage>[];
  String _draftText = '';
  XFile? _pendingAttachment;
  bool _isPickingImage = false;
  HomeOverlayMode _overlayMode = HomeOverlayMode.none;
  HomeVoiceState _voiceState = HomeVoiceState.idle;
  Timer? _recordingTicker;
  Duration _recordingDuration = Duration.zero;
  String? _voiceBubbleText;
  String? _voiceErrorMessage;
  String? _latestTranscriptText;
  String? _latestAssistantText;

  bool get _canSend =>
      _draftText.trim().isNotEmpty || _pendingAttachment != null;
  bool get _isChatMode => _overlayMode == HomeOverlayMode.chat;
  bool get _isImmersiveMode => _overlayMode != HomeOverlayMode.none;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleInputChanged);
    _focusNode = FocusNode();
    _messageScrollController = ScrollController();
    _voiceRecorder =
        widget.voiceRecorder ?? DeviceVoiceRecorderController();
    _voicePlayer = widget.voicePlayer ?? DeviceVoicePlayerController();
    _restoreLostAttachmentIfNeeded();
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    _messageScrollController.dispose();
    unawaited(_voiceRecorder.dispose());
    unawaited(_voicePlayer.dispose());
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {
      _draftText = _controller.text;
    });
  }

  Future<void> _setOverlayMode(HomeOverlayMode mode) async {
    if (_overlayMode == mode) {
      return;
    }
    if (_overlayMode == HomeOverlayMode.voice && mode != HomeOverlayMode.voice) {
      await _resetVoiceMode();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _overlayMode = mode;
    });
    widget.onOverlayModeChanged?.call(mode);
  }

  Future<void> _restoreLostAttachmentIfNeeded() async {
    final shouldAttemptRestore =
        widget.retrieveLostData != null ||
        (widget.pickImage == null && Platform.isAndroid);
    if (!shouldAttemptRestore) {
      return;
    }

    final response = widget.retrieveLostData != null
        ? await widget.retrieveLostData!.call()
        : await _imagePicker.retrieveLostData();
    if (!mounted || response.isEmpty) {
      return;
    }

    final restoredFile = response.files?.isNotEmpty == true
        ? response.files!.first
        : response.file;
    if (restoredFile == null) {
      return;
    }

    setState(() {
      _pendingAttachment = restoredFile;
      _overlayMode = HomeOverlayMode.chat;
    });
    widget.onOverlayModeChanged?.call(HomeOverlayMode.chat);
  }

  Future<void> _handleAttachmentTap(ImageSource source) async {
    if (_isPickingImage) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });
    try {
      final image = widget.pickImage != null
          ? await widget.pickImage!(source)
          : await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (!mounted || image == null) {
        return;
      }
      setState(() {
        _pendingAttachment = image;
        _overlayMode = HomeOverlayMode.chat;
      });
      widget.onOverlayModeChanged?.call(HomeOverlayMode.chat);
      _focusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removePendingAttachment() {
    setState(() {
      _pendingAttachment = null;
    });
  }

  Future<void> _sendMessage() async {
    final message = _draftText.trim();
    final attachment = _pendingAttachment;
    if (message.isEmpty && attachment == null) {
      return;
    }

    final createdAt = DateTime.now();
    setState(() {
      if (attachment != null) {
        _localMessages.add(
          _HomeChatMessage(
            imagePath: attachment.path,
            createdAt: createdAt,
            isCurrentUser: true,
          ),
        );
      }
      _controller.clear();
      _draftText = '';
      _pendingAttachment = null;
    });

    final session = await ref.read(sessionProvider.future);
    final backendMessage = message.isNotEmpty
        ? message
        : (attachment != null ? '画像を1枚送った' : '');
    if (backendMessage.isNotEmpty) {
      try {
        await ref
            .read(sendChatMessageControllerProvider)
            .send(session: session, text: backendMessage);
      } catch (_) {}
    }
    _scrollMessagesToBottom();
  }

  Future<void> _handleVoicePrimaryTap() async {
    switch (_voiceState) {
      case HomeVoiceState.recording:
        await _finishVoiceRecording();
        return;
      case HomeVoiceState.playing:
        await _voicePlayer.stop();
        if (!mounted) {
          return;
        }
        setState(() {
          _voiceState = HomeVoiceState.idle;
        });
        return;
      case HomeVoiceState.uploading:
        return;
      case HomeVoiceState.idle:
      case HomeVoiceState.error:
        await _startVoiceRecording();
        return;
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      await _voicePlayer.stop();
      await _voiceRecorder.start();
      if (!mounted) {
        return;
      }
      _recordingTicker?.cancel();
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
      setState(() {
        _voiceState = HomeVoiceState.recording;
        _recordingDuration = Duration.zero;
        _voiceErrorMessage = null;
        _voiceBubbleText = '声を聞いている。終わったらもう一度押して送って。';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceState = HomeVoiceState.error;
        _voiceErrorMessage = error.toString();
        _voiceBubbleText = 'マイクを使えなかった。権限を確認してもう一度。';
      });
    }
  }

  Future<void> _finishVoiceRecording() async {
    _recordingTicker?.cancel();
    setState(() {
      _voiceState = HomeVoiceState.uploading;
      _recordingDuration = Duration.zero;
      _voiceErrorMessage = null;
      _voiceBubbleText = '今の声を受け取っている。少し待って。';
    });

    try {
      final clip = await _voiceRecorder.stop();
      if (clip == null || clip.audioBytes.isEmpty) {
        throw const VoiceControllerException('録音データを取得できませんでした。');
      }

      final session = await ref.read(sessionProvider.future);
      final result = await ref
          .read(sendVoiceMessageControllerProvider)
          .send(
            session: session,
            audioBytes: clip.audioBytes,
            mimeType: clip.mimeType,
            durationMs: clip.durationMs,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _latestTranscriptText = result.transcriptText;
        _latestAssistantText = result.assistantText;
        _voiceBubbleText = result.assistantText;
        _voiceErrorMessage = result.audioStatus == VoiceChatAudioStatus.failed
            ? '音声の再生はできなかったけれど、返答テキストは受け取れた。'
            : null;
      });

      final audioBytes = result.assistantAudioBytes;
      final mimeType = result.assistantAudioMimeType;
      if (result.audioStatus == VoiceChatAudioStatus.ready &&
          audioBytes != null &&
          audioBytes.isNotEmpty &&
          mimeType != null &&
          mimeType.isNotEmpty) {
        setState(() {
          _voiceState = HomeVoiceState.playing;
        });
        await _voicePlayer.play(audioBytes, mimeType: mimeType);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _voiceState = HomeVoiceState.idle;
      });
      _scrollMessagesToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceState = HomeVoiceState.error;
        _voiceErrorMessage = error.toString();
        _voiceBubbleText = 'うまく聞き取れなかった。短く区切ってもう一度話してみよう。';
      });
    }
  }

  Future<void> _resetVoiceMode() async {
    _recordingTicker?.cancel();
    if (_voiceState == HomeVoiceState.recording) {
      await _voiceRecorder.cancel();
    }
    await _voicePlayer.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceState = HomeVoiceState.idle;
      _voiceErrorMessage = null;
      _voiceBubbleText = null;
      _recordingDuration = Duration.zero;
    });
  }

  void _scrollMessagesToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }
      _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    final session = ref.watch(sessionProvider).valueOrNull;
    final threadId = session?.threadId;
    final characterId = session?.characterId;
    final serverMessages = threadId == null
        ? const <ChatMessage>[]
        : ref.watch(chatMessagesProvider(threadId)).valueOrNull ??
              const <ChatMessage>[];
    if (threadId != null) {
      ref.listen<AsyncValue<List<ChatMessage>>>(
        chatMessagesProvider(threadId),
        (previous, next) {
          final resolvedClientIds =
              next.valueOrNull
                  ?.map((message) => message.clientMessageId)
                  .whereType<String>() ??
              const Iterable<String>.empty();
          ref
              .read(pendingMessagesProvider.notifier)
              .markCompleted(resolvedClientIds);
          if (_isChatMode) {
            _scrollMessagesToBottom();
          }
        },
      );
    }
    final pendingMessages = threadId == null
        ? const <PendingChatMessage>[]
        : ref
              .watch(pendingMessagesProvider)
              .where((message) => message.threadId == threadId)
              .toList(growable: false);
    final timelineMessages = _buildTimelineMessages(
      serverMessages: serverMessages,
      pendingMessages: pendingMessages,
      localMessages: _localMessages,
    );
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    final resolvedCharacterImageUrl = ref.watch(
      resolvedImageUrlProvider(character?.latestImageUrl),
    );
    final dailyBubble = session == null
        ? null
        : ref.watch(dailyBubbleProvider(session)).valueOrNull;
    final bubbleText =
        _voiceBubbleText ??
        dailyBubble?.text ??
        character?.starterGreeting ??
        widget.initialBubbleMessage;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxStageWidth = math.max(
              constraints.maxWidth - (_horizontalPadding * 2),
              0.0,
            );
            final stageHeight = math.min(
              maxStageWidth / 0.96,
              math.max(constraints.maxHeight * 0.38, 240.0),
            );
            final stage = SizedBox(
              key: const ValueKey<String>('home-room-stage-shell'),
              width: stageHeight * 0.96,
              height: stageHeight,
              child: HomeRoomStage(
                characterImageUrl: resolvedCharacterImageUrl.valueOrNull,
                isResolvingImage: resolvedCharacterImageUrl.isLoading,
              ),
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: _HomeTopBar(
                    showBackButton: _isImmersiveMode,
                    onBackTap: () {
                      unawaited(_setOverlayMode(HomeOverlayMode.none));
                    },
                    onSettingsTap: widget.onSettingsTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: _HomeBubble(text: bubbleText, isLive: _voiceState != HomeVoiceState.idle),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildBody(
                    context: context,
                    stage: stage,
                    timelineMessages: timelineMessages,
                  ),
                ),
                if (!_isImmersiveMode) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SizedBox(
                      height: _actionBarHeight,
                      child: _RoomActionBar(
                        selectedMode: _overlayMode,
                        onModeSelected: (mode) {
                          unawaited(_setOverlayMode(mode));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: GlassBottomDock.reservedBottomSpacing + 12,
                  ),
                ] else
                  const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required Widget stage,
    required List<_HomeChatMessage> timelineMessages,
  }) {
    if (_isChatMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final chatStageHeight = math.min(
            220.0,
            math.max(constraints.maxHeight * 0.24, 120.0),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                SizedBox(height: chatStageHeight, child: Center(child: stage)),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey<String>('home-message-layer'),
                    controller: _messageScrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemBuilder: (context, index) {
                      final message = timelineMessages[index];
                      return ChatMessageBubble(
                        key: ValueKey<String>(
                          message.isCurrentUser
                              ? 'home-user-bubble-$index'
                              : 'home-assistant-bubble-$index',
                        ),
                        text: message.text,
                        imagePath: message.imagePath,
                        isCurrentUser: message.isCurrentUser,
                        showAvatar: !message.isCurrentUser,
                        timestamp: _timestampFromDateTime(message.createdAt),
                        statusLabel: message.statusLabel,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: timelineMessages.length,
                  ),
                ),
                if (_pendingAttachment != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PendingAttachmentPreview(
                      attachment: _pendingAttachment!,
                      onRemove: _removePendingAttachment,
                    ),
                  ),
                const SizedBox(height: 10),
                ChatInputBar(
                  key: const ValueKey<String>('home-chat-input-bar'),
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: 'メッセージ',
                  sendEnabled: _canSend,
                  onSubmitted: (_) {
                    unawaited(_sendMessage());
                  },
                  onSendTap: () {
                    unawaited(_sendMessage());
                  },
                  onCameraTap: () {
                    unawaited(_handleAttachmentTap(ImageSource.camera));
                  },
                  onImageTap: () {
                    unawaited(_handleAttachmentTap(ImageSource.gallery));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    }

    final panel = switch (_overlayMode) {
      HomeOverlayMode.voice => _VoicePanel(
          voiceState: _voiceState,
          recordingDuration: _recordingDuration,
          transcriptText: _latestTranscriptText,
          assistantText: _latestAssistantText,
          errorText: _voiceErrorMessage,
          onPrimaryTap: () {
            unawaited(_handleVoicePrimaryTap());
          },
        ),
      HomeOverlayMode.photo => _PhotoPanel(
          isBusy: _isPickingImage,
          onCameraTap: () {
            unawaited(_handleAttachmentTap(ImageSource.camera));
          },
          onGalleryTap: () {
            unawaited(_handleAttachmentTap(ImageSource.gallery));
          },
        ),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Expanded(child: Center(child: stage)),
          if (panel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: panel,
            ),
        ],
      ),
    );
  }
}

List<_HomeChatMessage> _buildTimelineMessages({
  required List<ChatMessage> serverMessages,
  required List<PendingChatMessage> pendingMessages,
  required List<_HomeChatMessage> localMessages,
}) {
  final timeline = <_HomeChatMessage>[
    ...localMessages,
    for (final message in serverMessages)
      _HomeChatMessage(
        text: message.text,
        createdAt: message.createdAt,
        isCurrentUser: message.role == ChatRole.user,
      ),
    for (final message in pendingMessages)
      _HomeChatMessage(
        text: message.text,
        createdAt: message.createdAt,
        isCurrentUser: true,
        statusLabel: message.failed ? '再送待ち' : '送信中',
      ),
  ]..sort((left, right) => left.createdAt.compareTo(right.createdAt));
  return timeline;
}

String _timestampFromDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.showBackButton,
    required this.onBackTap,
    required this.onSettingsTap,
  });

  final bool showBackButton;
  final VoidCallback onBackTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: showBackButton
              ? _RoundIconButton(
                  buttonKey: const ValueKey<String>('home-chat-back-button'),
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: '戻る',
                  color: palette.headerText,
                  onPressed: onBackTap,
                )
              : null,
        ),
        const Spacer(),
        _RoundIconButton(
          buttonKey: const ValueKey<String>('home-settings-button'),
          icon: Icons.settings_outlined,
          tooltip: '設定',
          color: palette.settingsIcon,
          onPressed: onSettingsTap,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        color: color,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _HomeBubble extends StatelessWidget {
  const _HomeBubble({required this.text, required this.isLive});

  final String text;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    final bubbleRadius = BorderRadius.circular(32);

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: bubbleRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  key: const ValueKey<String>('home-daily-bubble'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: bubbleRadius,
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.94),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.panelShadow.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLive)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 8, right: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEE7D9C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF3E3B42),
                            height: 1.34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -21,
              left: 44,
              child: CustomPaint(
                painter: _SpeechBubbleTailPainter(
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  borderColor: Colors.white.withValues(alpha: 0.94),
                  shadowColor: palette.panelShadow.withValues(alpha: 0.2),
                ),
                child: const SizedBox(width: 42, height: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  const _SpeechBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.82, 0)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.08,
        size.width * 0.3,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.86,
        size.width * 0.04,
        size.height * 0.98,
      )
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.9,
        size.width * 0.52,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.42,
        size.width * 0.96,
        size.height * 0.1,
      )
      ..close();

    canvas.drawShadow(path, shadowColor, 8, false);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class _RoomActionBar extends StatelessWidget {
  const _RoomActionBar({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final HomeOverlayMode selectedMode;
  final ValueChanged<HomeOverlayMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('home-action-bar'),
      children: [
        Expanded(
          child: _RoomActionButton(
            buttonKey: const ValueKey<String>('home-action-voice'),
            icon: Icons.mic_rounded,
            tooltip: '音声',
            selected: selectedMode == HomeOverlayMode.voice,
            baseColor: const Color(0xFFF7C4D6),
            borderColor: const Color(0xFFCA7A9A),
            iconColor: const Color(0xFF8E4764),
            onPressed: () => onModeSelected(HomeOverlayMode.voice),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoomActionButton(
            buttonKey: const ValueKey<String>('home-action-photo'),
            icon: Icons.photo_camera_rounded,
            tooltip: '写真',
            selected: selectedMode == HomeOverlayMode.photo,
            baseColor: const Color(0xFFF9E98C),
            borderColor: const Color(0xFFB89E3C),
            iconColor: const Color(0xFF6C5A11),
            onPressed: () => onModeSelected(HomeOverlayMode.photo),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoomActionButton(
            buttonKey: const ValueKey<String>('home-action-chat'),
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'チャット',
            selected: selectedMode == HomeOverlayMode.chat,
            baseColor: const Color(0xFFB8DFFF),
            borderColor: const Color(0xFF6B94BE),
            iconColor: const Color(0xFF45678E),
            onPressed: () => onModeSelected(HomeOverlayMode.chat),
          ),
        ),
      ],
    );
  }
}

class _RoomActionButton extends StatelessWidget {
  const _RoomActionButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.baseColor,
    required this.borderColor,
    required this.iconColor,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final bool selected;
  final Color baseColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fillColor = selected
        ? baseColor
        : Color.lerp(baseColor, Colors.white, 0.22)!;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 2.6),
            ),
            child: Center(child: Icon(icon, size: 30, color: iconColor)),
          ),
        ),
      ),
    );
  }
}

class _VoicePanel extends StatelessWidget {
  const _VoicePanel({
    required this.voiceState,
    required this.recordingDuration,
    required this.transcriptText,
    required this.assistantText,
    required this.errorText,
    required this.onPrimaryTap,
  });

  final HomeVoiceState voiceState;
  final Duration recordingDuration;
  final String? transcriptText;
  final String? assistantText;
  final String? errorText;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (voiceState) {
      HomeVoiceState.recording => '送信する',
      HomeVoiceState.uploading => '処理中',
      HomeVoiceState.playing => '再生中',
      HomeVoiceState.error => 'もう一度',
      HomeVoiceState.idle => '押して話す',
    };
    final helper = switch (voiceState) {
      HomeVoiceState.recording =>
        '録音中 ${_formatRecordingDuration(recordingDuration)}',
      HomeVoiceState.uploading => '文字起こしと返答を生成しています',
      HomeVoiceState.playing => '返答音声を再生しています',
      HomeVoiceState.error => '短く区切ってもう一度試してください',
      HomeVoiceState.idle => '押して話し、もう一度押すと送信します',
    };

    return _PanelShell(
      child: Column(
        key: const ValueKey<String>('home-voice-mode'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Voice', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(helper),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey<String>('home-voice-primary-button'),
            onPressed: voiceState == HomeVoiceState.uploading ? null : onPrimaryTap,
            icon: Icon(
              switch (voiceState) {
                HomeVoiceState.recording => Icons.stop_rounded,
                HomeVoiceState.uploading => Icons.hourglass_top_rounded,
                HomeVoiceState.playing => Icons.volume_up_rounded,
                HomeVoiceState.error => Icons.refresh_rounded,
                HomeVoiceState.idle => Icons.mic_rounded,
              },
            ),
            label: Text(label),
          ),
          if (transcriptText != null && transcriptText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoChip(title: 'あなたの声', body: transcriptText!),
          ],
          if (assistantText != null && assistantText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoChip(title: '返答', body: assistantText!),
          ],
          if (errorText != null && errorText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
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

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({
    required this.isBusy,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final bool isBusy;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('写真を選ぶと、そのままチャット入力に添付します。'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('home-photo-camera-button'),
                  onPressed: isBusy ? null : onCameraTap,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('撮る'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey<String>('home-photo-gallery-button'),
                  onPressed: isBusy ? null : onGalleryTap,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('選ぶ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-voice-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

class _PendingAttachmentPreview extends StatelessWidget {
  const _PendingAttachmentPreview({
    required this.attachment,
    required this.onRemove,
  });

  final XFile attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-chat-pending-preview'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _PendingAttachmentThumbnail(path: attachment.path),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachment.path.split(RegExp(r'[\\/]')).last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('home-chat-pending-preview-remove'),
            onPressed: onRemove,
            tooltip: '添付を外す',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PendingAttachmentThumbnail extends StatelessWidget {
  const _PendingAttachmentThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        height: 68,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : const Icon(Icons.image_outlined),
      ),
    );
  }
}

class _HomeChatMessage {
  const _HomeChatMessage({
    this.text,
    this.imagePath,
    required this.createdAt,
    required this.isCurrentUser,
    this.statusLabel,
  });

  final String? text;
  final String? imagePath;
  final DateTime createdAt;
  final bool isCurrentUser;
  final String? statusLabel;
}

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_voice.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nes_ui/nes_ui.dart';

typedef HomeChatImagePicker = Future<XFile?> Function(ImageSource source);
typedef HomeChatLostDataRetriever = Future<LostDataResponse> Function();

enum HomeOverlayMode { none, voice, photo, chat }

enum HomeVoiceState { idle, recording, uploading, playing, error }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    required this.onDiaryTap,
    this.onOverlayModeChanged,
    this.initialBubbleMessage = '昨日の流れは残っている。今日は一つだけ進めよう、自分。',
    this.pickImage,
    this.retrieveLostData,
    this.voiceRecorder,
    this.voicePlayer,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onDiaryTap;
  final ValueChanged<HomeOverlayMode>? onOverlayModeChanged;
  final String initialBubbleMessage;
  final HomeChatImagePicker? pickImage;
  final HomeChatLostDataRetriever? retrieveLostData;
  final VoiceRecorderController? voiceRecorder;
  final VoicePlayerController? voicePlayer;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _horizontalPadding = 18.0;
  static const _actionBarHeight = 84.0;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _messageScrollController;
  late final VoiceRecorderController _voiceRecorder;
  late final VoicePlayerController _voicePlayer;
  final ImagePicker _imagePicker = ImagePicker();
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
  bool _isSubmittingImage = false;
  double _lastKeyboardInset = 0;
  String? _lastPlayedAssistantMessageId;

  bool get _canSend =>
      _draftText.trim().isNotEmpty || _pendingAttachment != null;
  bool get _isChatMode => _overlayMode == HomeOverlayMode.chat;
  bool get _isImmersiveMode => _overlayMode != HomeOverlayMode.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController()..addListener(_handleInputChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
    _messageScrollController = ScrollController();
    _voiceRecorder = widget.voiceRecorder ?? DeviceVoiceRecorderController();
    _voicePlayer = widget.voicePlayer ?? DeviceVoicePlayerController();
    _restoreLostAttachmentIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTicker?.cancel();
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.removeListener(_handleFocusChanged);
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

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _scrollMessagesToBottom();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_isChatMode && _focusNode.hasFocus) {
      _scrollMessagesToBottom();
    }
  }

  Future<void> _setOverlayMode(HomeOverlayMode mode) async {
    if (_overlayMode == mode) {
      return;
    }
    if (_overlayMode == HomeOverlayMode.voice &&
        mode != HomeOverlayMode.voice) {
      await _resetVoiceMode();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _overlayMode = mode;
    });
    widget.onOverlayModeChanged?.call(mode);
    if (mode == HomeOverlayMode.chat) {
      _scrollMessagesToBottom(jump: true);
    }
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

    setState(() {
      _controller.clear();
      _draftText = '';
      _pendingAttachment = null;
    });

    final session = await ref.read(sessionProvider.future);
    try {
      await ref
          .read(sendChatMessageControllerProvider)
          .send(
            session: session,
            text: message,
            imageBytes: attachment == null
                ? null
                : await attachment.readAsBytes(),
            imageMimeType: attachment == null
                ? null
                : _inferImageMimeTypeFromPath(attachment.path),
            imageFilename: attachment?.name,
            localImagePath: attachment?.path,
          );
    } catch (_) {}
    _scrollMessagesToBottom();
  }

  Future<void> _handleRegenerateTap() async {
    if (_isSubmittingImage) {
      return;
    }

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RegenerateImageSheet(),
    );

    if (!mounted || note == null) {
      return;
    }

    setState(() {
      _isSubmittingImage = true;
    });

    try {
      await ref
          .read(regenerateCharacterImageControllerProvider)
          .regenerate(reportText: note, title: '更新した姿');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('画像の再生成を開始しました')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('画像の再生成に失敗しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingImage = false;
        });
      }
    }
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
          mimeType.isNotEmpty &&
          _shouldPlayAssistantVoice(result.assistantMessageId)) {
        setState(() {
          _voiceState = HomeVoiceState.playing;
        });
        _lastPlayedAssistantMessageId = result.assistantMessageId;
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

  bool _shouldPlayAssistantVoice(String? assistantMessageId) {
    if (assistantMessageId == null || assistantMessageId.isEmpty) {
      return true;
    }
    return _lastPlayedAssistantMessageId != assistantMessageId;
  }

  void _scrollMessagesToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }
      final target = _messageScrollController.position.maxScrollExtent;
      if (jump) {
        _messageScrollController.jumpTo(target);
        return;
      }
      _messageScrollController.animateTo(
        target,
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
    );
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    final resolvedCharacterImageUrl = ref.watch(
      resolvedImageUrlProvider(character?.latestImageUrl),
    );
    final rawCharacterImageUrl = character?.latestImageUrl;
    final stageState = resolvedCharacterImageUrl.isLoading
        ? HomeRoomStageState.loading
        : (rawCharacterImageUrl == null || rawCharacterImageUrl.isEmpty)
        ? HomeRoomStageState.empty
        : (resolvedCharacterImageUrl.hasError ||
              resolvedCharacterImageUrl.valueOrNull == null ||
              resolvedCharacterImageUrl.valueOrNull!.isEmpty)
        ? HomeRoomStageState.error
        : HomeRoomStageState.ready;
    final stageMessage = switch (stageState) {
      HomeRoomStageState.loading => '画像を準備しています',
      HomeRoomStageState.empty => 'まだ画像がありません',
      HomeRoomStageState.error => '通信に失敗しました',
      HomeRoomStageState.ready => '',
    };
    final imageStatusLabel = switch (character?.imageStatus) {
      CharacterImageStatus.generating => '生成中',
      CharacterImageStatus.ready => '',
      CharacterImageStatus.failed => '再生成に失敗',
      _ => '',
    };
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
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxStageWidth = math.max(
                constraints.maxWidth - (_horizontalPadding * 2),
                0.0,
              );
              final desiredStageHeight = _isImmersiveMode
                  ? constraints.maxHeight * 0.42
                  : constraints.maxHeight * 0.63;
              final stageSize = math.min(
                maxStageWidth,
                math.max(desiredStageHeight, _isImmersiveMode ? 260.0 : 360.0),
              );
              final stage = SizedBox(
                key: const ValueKey<String>('home-room-stage-shell'),
                width: stageSize,
                height: stageSize,
                child: HomeRoomStage(
                  imageUrl: resolvedCharacterImageUrl.valueOrNull,
                  state: stageState,
                  message: stageMessage,
                ),
              );

              return Stack(
                children: [
                  Positioned(
                    top: 72,
                    left: -30,
                    child: _HomeGlow(
                      size: 170,
                      color: palette.panelGlow.withValues(alpha: 0.54),
                    ),
                  ),
                  Positioned(
                    top: 280,
                    right: -24,
                    child: _HomeGlow(
                      size: 140,
                      color: palette.panelFill.withValues(alpha: 0.62),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _HomeBubble(
                                text: bubbleText,
                                isLive: _voiceState != HomeVoiceState.idle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _PixelToolbarButton(
                              buttonKey: const ValueKey<String>(
                                'home-settings-button',
                              ),
                              icon: NesIcons.wrench,
                              tooltip: '設定',
                              onPressed: widget.onSettingsTap,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBody(
                          context: context,
                          stage: stage,
                          timelineMessages: timelineMessages,
                          imageStatusLabel: imageStatusLabel,
                          characterName: character?.name ?? 'Self',
                        ),
                      ),
                      if (!_isImmersiveMode) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: SizedBox(
                            height: _actionBarHeight + 8,
                            child: _RoomActionBar(
                              selectedMode: _overlayMode,
                              onModeSelected: (mode) {
                                unawaited(_setOverlayMode(mode));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else
                        const SizedBox(height: 12),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required Widget stage,
    required List<_HomeChatMessage> timelineMessages,
    required String imageStatusLabel,
    required String characterName,
  }) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (_isChatMode && keyboardInset != _lastKeyboardInset) {
      _lastKeyboardInset = keyboardInset;
      if (keyboardInset > 0) {
        _scrollMessagesToBottom();
      }
    }

    if (_isChatMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final chatStageHeight = math.min(
            220.0,
            math.max(constraints.maxHeight * 0.24, 120.0),
          );

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(18, 0, 18, keyboardInset),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InlineDismissButton(
                      buttonKey: const ValueKey<String>(
                        'home-chat-back-button',
                      ),
                      onPressed: () {
                        unawaited(_setOverlayMode(HomeOverlayMode.none));
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: chatStageHeight,
                  child: Center(child: stage),
                ),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey<String>('home-message-layer'),
                    controller: _messageScrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemBuilder: (context, index) {
                      final message = timelineMessages[index];
                      final resolvedMessageImageUrl = message.imageUrl == null
                          ? null
                          : ref
                                    .watch(
                                      resolvedImageUrlProvider(
                                        message.imageUrl,
                                      ),
                                    )
                                    .valueOrNull ??
                                (message.imageUrl!.startsWith('http')
                                    ? message.imageUrl
                                    : null);
                      return ChatMessageBubble(
                        key: ValueKey<String>(
                          message.isCurrentUser
                              ? 'home-user-bubble-$index'
                              : 'home-assistant-bubble-$index',
                        ),
                        text: message.text,
                        imagePath: message.localImagePath,
                        imageUrl: resolvedMessageImageUrl,
                        isCurrentUser: message.isCurrentUser,
                        showAvatar: !message.isCurrentUser,
                        timestamp: _timestampFromDateTime(message.createdAt),
                        statusLabel: message.statusLabel,
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
        onClose: () {
          unawaited(_setOverlayMode(HomeOverlayMode.none));
        },
        onPrimaryTap: () {
          unawaited(_handleVoicePrimaryTap());
        },
      ),
      HomeOverlayMode.photo => _PhotoPanel(
        isBusy: _isPickingImage,
        onClose: () {
          unawaited(_setOverlayMode(HomeOverlayMode.none));
        },
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 6),
              child: _HomeHeroPanel(
                stage: stage,
                imageStatusLabel: imageStatusLabel,
                characterName: characterName,
                isSubmittingImage: _isSubmittingImage,
                onDiaryTap: widget.onDiaryTap,
                onRegenerateTap: () {
                  unawaited(_handleRegenerateTap());
                },
              ),
            ),
          ),
          if (panel != null)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 12),
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
}) {
  final timeline = <_HomeChatMessage>[
    for (final message in serverMessages)
      _HomeChatMessage(
        text: message.text,
        createdAt: message.createdAt,
        isCurrentUser: message.role == ChatRole.user,
        imageUrl: message.imageUrl,
      ),
    for (final message in pendingMessages)
      _HomeChatMessage(
        text: message.text,
        createdAt: message.createdAt,
        isCurrentUser: true,
        statusLabel: message.failed ? '再送待ち' : '送信中',
        localImagePath: message.localImagePath,
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

class _PixelToolbarButton extends StatelessWidget {
  const _PixelToolbarButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Key buttonKey;
  final NesIconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: NesButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        type: NesButtonType.normal,
        icon: icon,
        iconSize: const Size.square(18),
        buttonWidth: 28,
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

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NesContainer(
              key: const ValueKey<String>('home-daily-bubble'),
              backgroundColor: Colors.white.withValues(alpha: 0.94),
              borderColor: palette.panelOutline,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              painterBuilder: NesContainerSquareCornerPainter.new,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLive)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      color: palette.transcriptBadgeIcon,
                    ),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.headerText,
                        height: 1.34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(left: 40, bottom: -12, child: _BubbleTail()),
          ],
        ),
      ),
    );
  }
}

class _BubbleTail extends StatelessWidget {
  const _BubbleTail();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _TailBlock(width: 18, height: 8),
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: _TailBlock(width: 12, height: 8),
        ),
        Padding(
          padding: EdgeInsets.only(left: 14),
          child: _TailBlock(width: 8, height: 8),
        ),
      ],
    );
  }
}

class _TailBlock extends StatelessWidget {
  const _TailBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: palette.panelOutline, width: 2),
      ),
    );
  }
}

class _HomeGlow extends StatelessWidget {
  const _HomeGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _HomeHeroPanel extends StatelessWidget {
  const _HomeHeroPanel({
    required this.stage,
    required this.imageStatusLabel,
    required this.characterName,
    required this.isSubmittingImage,
    required this.onDiaryTap,
    required this.onRegenerateTap,
  });

  final Widget stage;
  final String imageStatusLabel;
  final String characterName;
  final bool isSubmittingImage;
  final VoidCallback onDiaryTap;
  final VoidCallback onRegenerateTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;

    return NesContainer(
      backgroundColor: Colors.white.withValues(alpha: 0.74),
      borderColor: palette.panelOutline,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      painterBuilder: NesContainerSquareCornerPainter.new,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: palette.panelShadow.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (imageStatusLabel.isNotEmpty) ...[
                _StatusPill(
                  label: imageStatusLabel,
                  fillColor: palette.transcriptBadgeFill,
                  textColor: palette.transcriptTitle,
                ),
                const SizedBox(width: 8),
              ],
              _StatusPill(
                label: characterName,
                fillColor: palette.panelFill,
                textColor: palette.headerText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          stage,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  actionKey: const ValueKey<String>('home-diary-entry'),
                  title: 'Diary',
                  subtitle: '今日までの記録を見る',
                  fillColor: const Color(0xFFFFE9D3),
                  borderColor: const Color(0xFFC28B5E),
                  iconColor: const Color(0xFF8D5B39),
                  icon: NesIcons.textFile,
                  onTap: onDiaryTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  actionKey: const ValueKey<String>('home-image-regenerate'),
                  title: isSubmittingImage ? 'Generating' : 'Image',
                  subtitle: isSubmittingImage ? '再生成しています' : '最新の姿を更新する',
                  fillColor: const Color(0xFFFFE0EF),
                  borderColor: const Color(0xFFC7739A),
                  iconColor: const Color(0xFF8F4567),
                  icon: isSubmittingImage
                      ? NesIcons.hourglassMiddle
                      : NesIcons.redo,
                  onTap: isSubmittingImage ? null : onRegenerateTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.actionKey,
    required this.title,
    required this.subtitle,
    required this.fillColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  final Key actionKey;
  final String title;
  final String subtitle;
  final Color fillColor;
  final Color borderColor;
  final Color iconColor;
  final NesIconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.7 : 1,
      child: Semantics(
        button: true,
        child: NesPressable(
          key: actionKey,
          disabled: onTap == null,
          onPress: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.18),
                  offset: const Offset(0, 6),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NesIcon(
                  iconData: icon,
                  size: const Size.square(22),
                  primaryColor: iconColor,
                  secondaryColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'NotoSansJP',
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                    shadows: const [],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'NotoSansJP',
                    color: iconColor.withValues(alpha: 0.84),
                    height: 1.3,
                    decoration: TextDecoration.none,
                    shadows: const [],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.fillColor,
    required this.textColor,
  });

  final String label;
  final Color fillColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: textColor, width: 2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
            icon: NesIcons.audio,
            label: 'Voice',
            tooltip: '音声',
            selected: selectedMode == HomeOverlayMode.voice,
            fillColor: const Color(0xFFFFC5D8),
            borderColor: const Color(0xFFC36A93),
            iconColor: const Color(0xFF7E3055),
            onPressed: () => onModeSelected(HomeOverlayMode.voice),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoomActionButton(
            buttonKey: const ValueKey<String>('home-action-photo'),
            icon: NesIcons.camera,
            label: 'Photo',
            tooltip: '写真',
            selected: selectedMode == HomeOverlayMode.photo,
            fillColor: const Color(0xFFFFE79D),
            borderColor: const Color(0xFFB38D29),
            iconColor: const Color(0xFF6F5611),
            onPressed: () => onModeSelected(HomeOverlayMode.photo),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoomActionButton(
            buttonKey: const ValueKey<String>('home-action-chat'),
            icon: NesIcons.letter,
            label: 'Chat',
            tooltip: 'チャット',
            selected: selectedMode == HomeOverlayMode.chat,
            fillColor: const Color(0xFFBFE5FF),
            borderColor: const Color(0xFF5E8CB7),
            iconColor: const Color(0xFF315B87),
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
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.fillColor,
    required this.borderColor,
    required this.iconColor,
    required this.onPressed,
  });

  final Key buttonKey;
  final NesIconData icon;
  final String label;
  final String tooltip;
  final bool selected;
  final Color fillColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final resolvedFill = selected
        ? fillColor
        : Color.lerp(fillColor, Colors.white, 0.28)!;

    return AspectRatio(
      aspectRatio: 1,
      child: Semantics(
        button: true,
        label: tooltip,
        child: NesPressable(
          key: buttonKey,
          onPress: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: resolvedFill,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.18),
                  offset: const Offset(0, 7),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NesIcon(
                  iconData: icon,
                  size: const Size.square(22),
                  primaryColor: iconColor,
                  secondaryColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'NotoSansJP',
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                    shadows: const [],
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

class _VoicePanel extends StatelessWidget {
  const _VoicePanel({
    required this.voiceState,
    required this.recordingDuration,
    required this.transcriptText,
    required this.assistantText,
    required this.errorText,
    required this.onClose,
    required this.onPrimaryTap,
  });

  final HomeVoiceState voiceState;
  final Duration recordingDuration;
  final String? transcriptText;
  final String? assistantText;
  final String? errorText;
  final VoidCallback onClose;
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
      title: 'Voice',
      titleColor: const Color(0xFF583A4A),
      onClose: onClose,
      child: Column(
        key: const ValueKey<String>('home-voice-mode'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            helper,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'NotoSansJP',
              color: const Color(0xFF6B5662),
              height: 1.35,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              shadows: const [],
            ),
          ),
          const SizedBox(height: 14),
          _PanelActionButton(
            buttonKey: const ValueKey<String>('home-voice-primary-button'),
            label: label,
            fillColor: const Color(0xFFFFC6D9),
            borderColor: const Color(0xFFC36A93),
            textColor: const Color(0xFF6E2949),
            icon: switch (voiceState) {
              HomeVoiceState.recording => NesIcons.pause,
              HomeVoiceState.uploading => NesIcons.hourglassMiddle,
              HomeVoiceState.playing => NesIcons.audio,
              HomeVoiceState.error => NesIcons.redo,
              HomeVoiceState.idle => NesIcons.audio,
            },
            onPressed: voiceState == HomeVoiceState.uploading
                ? null
                : onPrimaryTap,
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
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'Photo',
      titleColor: const Color(0xFF5A4A37),
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '写真を選ぶと、そのままチャット入力に添付します。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'NotoSansJP',
              color: const Color(0xFF6F6357),
              height: 1.35,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              shadows: const [],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PanelActionButton(
                  buttonKey: const ValueKey<String>('home-photo-camera-button'),
                  label: '撮る',
                  fillColor: const Color(0xFFFFF1C4),
                  borderColor: const Color(0xFFBF9532),
                  textColor: const Color(0xFF6C5414),
                  icon: NesIcons.camera,
                  onPressed: isBusy ? null : onCameraTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PanelActionButton(
                  buttonKey: const ValueKey<String>(
                    'home-photo-gallery-button',
                  ),
                  label: '選ぶ',
                  fillColor: const Color(0xFFFFD9EB),
                  borderColor: const Color(0xFFC36A93),
                  textColor: const Color(0xFF6E2949),
                  icon: NesIcons.gallery,
                  onPressed: isBusy ? null : onGalleryTap,
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
  const _PanelShell({
    required this.title,
    required this.titleColor,
    required this.onClose,
    required this.child,
  });

  final String title;
  final Color titleColor;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      key: const ValueKey<String>('home-voice-panel'),
      backgroundColor: const Color(0xFFFFFCFD).withValues(alpha: 0.96),
      borderColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.all(18),
      painterBuilder: NesContainerSquareCornerPainter.new,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'NotoSansJP',
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  decoration: TextDecoration.none,
                  shadows: const [],
                ),
              ),
              const Spacer(),
              _InlineDismissButton(onPressed: onClose),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineDismissButton extends StatelessWidget {
  const _InlineDismissButton({this.buttonKey, required this.onPressed});

  final Key? buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '閉じる',
      child: NesPressable(
        key: buttonKey,
        onPress: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EDF3),
            border: Border.all(color: const Color(0xFF5F4A57), width: 3),
          ),
          alignment: Alignment.center,
          child: const Text(
            '×',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5F4A57),
              decoration: TextDecoration.none,
              shadows: [],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.buttonKey,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final NesIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.58 : 1,
      child: Semantics(
        button: true,
        child: NesPressable(
          key: buttonKey,
          disabled: onPressed == null,
          onPress: onPressed,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: borderColor, width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NesIcon(
                  iconData: icon,
                  size: const Size.square(18),
                  primaryColor: textColor,
                  secondaryColor: Colors.white,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      backgroundColor: const Color(0xFFF5F3F8),
      borderColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.all(14),
      painterBuilder: NesContainerSquareCornerPainter.new,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
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
    return NesContainer(
      key: const ValueKey<String>('home-chat-pending-preview'),
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      borderColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.all(10),
      painterBuilder: NesContainerSquareCornerPainter.new,
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
          NesIconButton(
            key: const ValueKey<String>('home-chat-pending-preview-remove'),
            onPress: onRemove,
            icon: NesIcons.close,
            size: const Size.square(20),
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

class _RegenerateImageSheet extends StatefulWidget {
  const _RegenerateImageSheet();

  @override
  State<_RegenerateImageSheet> createState() => _RegenerateImageSheetState();
}

class _RegenerateImageSheetState extends State<_RegenerateImageSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: NesContainer(
            backgroundColor: const Color(0xFFFFFBFD),
            borderColor: const Color(0xFF5F4A57),
            padding: const EdgeInsets.all(18),
            painterBuilder: NesContainerSquareCornerPainter.new,
            child: Column(
              key: const ValueKey<String>('home-image-regenerate-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '再生成メモ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.titleText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今回だけ反映したい雰囲気や補足を短く入れます。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.subtitleText),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    key: const ValueKey<String>('home-image-regenerate-input'),
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '少し春っぽい空気感にしたい、など',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _SheetActionButton(
                      label: '閉じる',
                      fillColor: const Color(0xFFF4E7EF),
                      borderColor: const Color(0xFF7B6672),
                      textColor: const Color(0xFF5F4A57),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _SheetActionButton(
                      buttonKey: const ValueKey<String>(
                        'home-image-regenerate-submit',
                      ),
                      label: '再生成',
                      fillColor: const Color(0xFFFFD9EB),
                      borderColor: const Color(0xFFC36A93),
                      textColor: const Color(0xFF6E2949),
                      onPressed: () {
                        Navigator.of(context).pop(_controller.text.trim());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    this.buttonKey,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final Key? buttonKey;
  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: NesPressable(
        key: buttonKey,
        onPress: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeChatMessage {
  const _HomeChatMessage({
    this.text,
    this.localImagePath,
    this.imageUrl,
    required this.createdAt,
    required this.isCurrentUser,
    this.statusLabel,
  });

  final String? text;
  final String? localImagePath;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isCurrentUser;
  final String? statusLabel;
}

String? _inferImageMimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

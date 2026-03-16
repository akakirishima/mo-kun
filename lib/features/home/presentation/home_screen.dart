import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';
import 'package:image_picker/image_picker.dart';

typedef HomeChatImagePicker = Future<XFile?> Function(ImageSource source);
typedef HomeChatLostDataRetriever = Future<LostDataResponse> Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    this.onOverlayModeChanged,
    this.initialMoriMessage = '今日も会えて嬉しいな。\n一緒にお話ししよ！',
    this.pickImage,
    this.retrieveLostData,
  });

  final VoidCallback onSettingsTap;
  final ValueChanged<HomeOverlayMode>? onOverlayModeChanged;
  final String initialMoriMessage;
  final HomeChatImagePicker? pickImage;
  final HomeChatLostDataRetriever? retrieveLostData;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum HomeOverlayMode { none, phone, photo, chat }

class _HomeScreenState extends State<HomeScreen> {
  static const _headerTop = 14.0;
  static const _stageActionGap = 16.0;
  static const _actionBarHeight = 92.0;
  static const _composerHeight = 76.0;
  static const _dockedBottomSpacing =
      GlassBottomDock.reservedBottomSpacing + 12.0;
  static const _immersiveBottomSpacing = 12.0;
  static const _horizontalPadding = 18.0;
  static const _stageHorizontalPadding = 8.0;
  static const _headerStageGap = 8.0;
  static const _messageSpacing = 12.0;
  static const _messageLayerPadding = EdgeInsets.only(
    left: 24,
    right: 2,
    top: 18,
    bottom: 6,
  );

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _messageScrollController;
  final ImagePicker _imagePicker = ImagePicker();
  final List<_HomeChatMessage> _messages = <_HomeChatMessage>[];
  String _draftText = '';
  XFile? _pendingAttachment;
  bool _isPickingImage = false;
  HomeOverlayMode _overlayMode = HomeOverlayMode.none;

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
    _restoreLostAttachmentIfNeeded();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {
      _draftText = _controller.text;
    });
  }

  void _setOverlayMode(HomeOverlayMode mode) {
    if (_overlayMode == mode) {
      return;
    }

    setState(() {
      _overlayMode = mode;
    });
    widget.onOverlayModeChanged?.call(mode);
  }

  void _exitImmersiveMode() {
    if (!_isImmersiveMode) {
      return;
    }

    _setOverlayMode(HomeOverlayMode.none);
  }

  Future<XFile?> _pickImage(ImageSource source) {
    final picker = widget.pickImage;
    if (picker != null) {
      return picker(source);
    }

    return _imagePicker.pickImage(source: source, imageQuality: 85);
  }

  Future<LostDataResponse> _retrieveLostData() {
    final retriever = widget.retrieveLostData;
    if (retriever != null) {
      return retriever();
    }

    return _imagePicker.retrieveLostData();
  }

  Future<void> _restoreLostAttachmentIfNeeded() async {
    final shouldAttemptRestore =
        widget.retrieveLostData != null ||
        (widget.pickImage == null && Platform.isAndroid);
    if (!shouldAttemptRestore) {
      return;
    }

    final response = await _retrieveLostData();
    if (!mounted || response.isEmpty) {
      return;
    }

    final files = response.files;
    final restoredFile = files != null && files.isNotEmpty
        ? files.first
        : response.file;
    if (restoredFile == null) {
      return;
    }

    setState(() {
      _pendingAttachment = restoredFile;
    });
    _setOverlayMode(HomeOverlayMode.chat);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _handleAttachmentTap(ImageSource source) async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _pickImage(source);
      if (!mounted || image == null) {
        return;
      }

      setState(() {
        _pendingAttachment = image;
      });
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
    if (_pendingAttachment == null) {
      return;
    }

    setState(() {
      _pendingAttachment = null;
    });
  }

  void _sendMessage() {
    final message = _draftText.trim();
    final attachment = _pendingAttachment;
    if (message.isEmpty && attachment == null) {
      return;
    }

    setState(() {
      if (attachment != null) {
        _messages.add(
          _HomeChatMessage(
            imagePath: attachment.path,
            timestamp: _timestampLabel(),
          ),
        );
      }

      if (message.isNotEmpty) {
        _messages.add(
          _HomeChatMessage(text: message, timestamp: _timestampLabel()),
        );
      }

      _controller.clear();
      _draftText = '';
      _pendingAttachment = null;
    });

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

    _focusNode.requestFocus();
  }

  String _timestampLabel() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    final isChatMode = _isChatMode;
    final isImmersiveMode = _isImmersiveMode;
    final composerBottom = isImmersiveMode
        ? _immersiveBottomSpacing
        : _dockedBottomSpacing;

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
              constraints.maxWidth - (_stageHorizontalPadding * 2),
              0.0,
            );
            final stageHeight = math.max(
              math.min(
                maxStageWidth / 0.96,
                math.max(constraints.maxHeight * 0.44, 0.0),
              ),
              0.0,
            );
            final stageWidth = stageHeight * 0.96;
            final stageShell = SizedBox(
              key: const ValueKey<String>('home-room-stage-shell'),
              width: stageWidth,
              height: stageHeight,
              child: const HomeRoomStage(
                key: ValueKey<String>('home-room-stage'),
              ),
            );

            return Column(
              key: const ValueKey<String>('home-screen'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    _headerTop,
                    _horizontalPadding,
                    0,
                  ),
                  child: _MoriHeaderCard(
                    message: widget.initialMoriMessage,
                    onSettingsTap: widget.onSettingsTap,
                    showBackButton: isImmersiveMode,
                    onBackTap: _exitImmersiveMode,
                  ),
                ),
                const SizedBox(height: _headerStageGap),
                if (isChatMode)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, stackConstraints) {
                        final messageLayerBottom =
                            _composerHeight + composerBottom + 12;
                        final availableStageHeight = math.max(
                          stackConstraints.maxHeight - messageLayerBottom,
                          0.0,
                        );
                        final chatStageHeight = math.min(
                          stageHeight,
                          availableStageHeight,
                        );
                        final chatStageWidth = chatStageHeight * 0.96;
                        final messageLayerTop = chatStageHeight * 0.52;
                        final messageLayerHeight = math.max(
                          stackConstraints.maxHeight -
                              messageLayerTop -
                              messageLayerBottom,
                          1.0,
                        );
                        final previewBottom =
                            composerBottom + _composerHeight + 10;
                        final chatStageShell = SizedBox(
                          key: const ValueKey<String>('home-room-stage-shell'),
                          width: chatStageWidth,
                          height: chatStageHeight,
                          child: const HomeRoomStage(
                            key: ValueKey<String>('home-room-stage'),
                          ),
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(child: chatStageShell),
                            ),
                            Positioned(
                              top: messageLayerTop,
                              left: 24,
                              right: 24,
                              child: SizedBox(
                                height: messageLayerHeight,
                                child: ClipRect(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x00FFFFFF),
                                          Color(0x77FFFFFF),
                                          Color(0xF2FFFFFF),
                                          Color(0xFFFFFFFF),
                                        ],
                                        stops: [0, 0.12, 0.24, 1],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: SingleChildScrollView(
                                      key: const ValueKey<String>(
                                        'home-message-layer',
                                      ),
                                      controller: _messageScrollController,
                                      physics: const BouncingScrollPhysics(),
                                      child: _MessageCanvas(
                                        minHeight: messageLayerHeight,
                                        padding: _messageLayerPadding,
                                        messages: _messages,
                                        includeKeys: true,
                                        allowOverflow: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_pendingAttachment != null)
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: previewBottom,
                                child: _HomePendingAttachmentPreview(
                                  attachment: _pendingAttachment!,
                                  onRemove: _removePendingAttachment,
                                ),
                              ),
                            Positioned(
                              left: _horizontalPadding,
                              right: _horizontalPadding,
                              bottom: composerBottom,
                              child: ChatInputBar(
                                key: const ValueKey<String>(
                                  'home-chat-input-bar',
                                ),
                                controller: _controller,
                                focusNode: _focusNode,
                                hintText: 'メッセージ',
                                sendEnabled: _canSend,
                                onSubmitted: (_) => _sendMessage(),
                                onSendTap: _sendMessage,
                                onCameraTap: () =>
                                    _handleAttachmentTap(ImageSource.camera),
                                onImageTap: () =>
                                    _handleAttachmentTap(ImageSource.gallery),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else ...[
                  SizedBox(
                    height: stageHeight,
                    child: Center(child: stageShell),
                  ),
                ],
                if (!isImmersiveMode) ...[
                  const SizedBox(height: _stageActionGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    child: SizedBox(
                      height: _actionBarHeight,
                      child: _RoomActionBar(
                        selectedMode: _overlayMode,
                        onModeSelected: _setOverlayMode,
                      ),
                    ),
                  ),
                ] else if (!isChatMode) ...[
                  const Spacer(),
                  SizedBox(
                    height: isImmersiveMode
                        ? _immersiveBottomSpacing
                        : _dockedBottomSpacing,
                  ),
                ],
              ],
            );
          },
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
            buttonKey: const ValueKey<String>('home-action-phone'),
            icon: Icons.call_rounded,
            tooltip: '電話',
            selected: selectedMode == HomeOverlayMode.phone,
            baseColor: const Color(0xFFF7C4D6),
            borderColor: const Color(0xFFCA7A9A),
            iconColor: const Color(0xFF8E4764),
            onPressed: () => onModeSelected(HomeOverlayMode.phone),
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
    final shadowColor = borderColor.withValues(alpha: selected ? 0.26 : 0.16);

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 2.6),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: selected ? 12 : 8,
                  offset: Offset(0, selected ? 6 : 4),
                ),
              ],
            ),
            child: Center(child: Icon(icon, size: 30, color: iconColor)),
          ),
        ),
      ),
    );
  }
}

class _MoriHeaderCard extends StatelessWidget {
  const _MoriHeaderCard({
    required this.message,
    required this.onSettingsTap,
    required this.showBackButton,
    this.onBackTap,
  });

  final String message;
  final VoidCallback onSettingsTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).home;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const ValueKey<String>('home-mori-card'),
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withValues(alpha: 0.6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
            boxShadow: [
              BoxShadow(
                color: palette.panelShadow.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.72),
                const Color(0xFFE7F8FF).withValues(alpha: 0.58),
                const Color(0xFFFFDCEC).withValues(alpha: 0.52),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: _HeaderIconButton(
                    buttonKey: const ValueKey<String>('home-chat-back-button'),
                    tooltip: '戻る',
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: palette.headerText,
                    onPressed: onBackTap,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: _MoriBadgeAvatar(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mori',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.headerText,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF3E3B42),
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                buttonKey: const ValueKey<String>('home-settings-button'),
                tooltip: '設定',
                icon: Icons.settings_outlined,
                color: palette.settingsIcon,
                onPressed: onSettingsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

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

class _MoriBadgeAvatar extends StatelessWidget {
  const _MoriBadgeAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC7DA), Color(0xFFFFEAF4)],
        ),
        border: Border.all(color: const Color(0xFFF09FBE), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24F09FBE),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 7,
            left: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE58D),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            'M',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF9A4E70),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({super.key, this.text, this.imagePath});

  final String? text;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final hasText = text != null && text!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: EdgeInsets.symmetric(
        horizontal: hasImage ? 8 : 16,
        vertical: hasImage ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFBFE3B4).withValues(alpha: 0.78),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFF5B9661), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2F5E38),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            _HomeChatImageAttachment(
              imagePath: imagePath!,
              imageKey: key is ValueKey<String>
                  ? ValueKey<String>(
                      '${(key! as ValueKey<String>).value}-image',
                    )
                  : null,
            ),
          if (hasImage && hasText) const SizedBox(height: 10),
          if (hasText)
            Text(
              text!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1F3726),
                fontWeight: FontWeight.w700,
                height: 1.24,
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageCanvas extends StatelessWidget {
  const _MessageCanvas({
    required this.minHeight,
    required this.padding,
    required this.messages,
    required this.includeKeys,
    required this.allowOverflow,
  });

  final double minHeight;
  final EdgeInsets padding;
  final List<_HomeChatMessage> messages;
  final bool includeKeys;
  final bool allowOverflow;

  @override
  Widget build(BuildContext context) {
    final estimatedHeight = math.max(
      minHeight,
      padding.vertical + (messages.length * 96.0),
    );

    final canvas = ConstrainedBox(
      constraints: BoxConstraints(minHeight: estimatedHeight),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: Alignment.bottomRight,
          child: _MessageColumn(messages: messages, includeKeys: includeKeys),
        ),
      ),
    );

    if (!allowOverflow) {
      return canvas;
    }

    return OverflowBox(
      alignment: Alignment.bottomRight,
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
      child: canvas,
    );
  }
}

class _MessageColumn extends StatelessWidget {
  const _MessageColumn({required this.messages, required this.includeKeys});

  final List<_HomeChatMessage> messages;
  final bool includeKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < messages.length; index++) ...[
          _UserMessageBubble(
            key: includeKeys
                ? ValueKey<String>('home-user-bubble-$index')
                : null,
            text: messages[index].text,
            imagePath: messages[index].imagePath,
          ),
          if (index != messages.length - 1)
            const SizedBox(height: _HomeScreenState._messageSpacing),
        ],
      ],
    );
  }
}

class _HomePendingAttachmentPreview extends StatelessWidget {
  const _HomePendingAttachmentPreview({
    required this.attachment,
    required this.onRemove,
  });

  final XFile attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;

    return Container(
      key: const ValueKey<String>('home-chat-pending-preview'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.composerShell.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: palette.composerIcon.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _HomePendingAttachmentThumbnail(path: attachment.path),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.composerText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>('home-chat-pending-preview-remove'),
            onPressed: onRemove,
            tooltip: '添付を外す',
            icon: const Icon(Icons.close_rounded),
            color: palette.composerIcon,
          ),
        ],
      ),
    );
  }
}

class _HomePendingAttachmentThumbnail extends StatelessWidget {
  const _HomePendingAttachmentThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final hasFile = file.existsSync();
    final palette = AppearanceScope.paletteOf(context).chat;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 68,
        height: 68,
        color: palette.composerFieldFill,
        child: hasFile
            ? Image.file(file, fit: BoxFit.cover)
            : Icon(Icons.image_outlined, color: palette.composerIcon),
      ),
    );
  }
}

class _HomeChatImageAttachment extends StatelessWidget {
  const _HomeChatImageAttachment({required this.imagePath, this.imageKey});

  final String imagePath;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final hasFile = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        key: imageKey,
        width: 188,
        height: 188,
        color: const Color(0xFFBFE3B4).withValues(alpha: 0.42),
        child: hasFile
            ? Image.file(file, fit: BoxFit.cover)
            : _MissingHomeChatImagePlaceholder(imagePath: imagePath),
      ),
    );
  }
}

class _MissingHomeChatImagePlaceholder extends StatelessWidget {
  const _MissingHomeChatImagePlaceholder({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final filename = imagePath.split(RegExp(r'[\\/]')).last;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 42, color: Color(0xFF35683E)),
          const SizedBox(height: 10),
          Text(
            filename,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1F3726),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeChatMessage {
  const _HomeChatMessage({this.text, this.imagePath, this.timestamp});

  final String? text;
  final String? imagePath;
  final String? timestamp;
}

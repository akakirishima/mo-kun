import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/widgets/home_room_stage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    this.onOverlayModeChanged,
    this.initialMoriMessage = '今日も会えて嬉しいな。\n一緒にお話ししよ！',
  });

  final VoidCallback onSettingsTap;
  final ValueChanged<HomeOverlayMode>? onOverlayModeChanged;
  final String initialMoriMessage;

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
  final List<String> _userMessages = <String>[];
  HomeOverlayMode _overlayMode = HomeOverlayMode.none;

  bool get _canSend => _controller.text.trim().isNotEmpty;
  bool get _isChatMode => _overlayMode == HomeOverlayMode.chat;
  bool get _isImmersiveMode => _overlayMode != HomeOverlayMode.none;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleInputChanged);
    _focusNode = FocusNode();
    _messageScrollController = ScrollController();
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
    setState(() {});
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

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() {
      _userMessages.add(message);
      _controller.clear();
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
            final maxStageWidth =
                constraints.maxWidth - (_stageHorizontalPadding * 2);
            final stageHeight = math.min(
              maxStageWidth / 0.96,
              constraints.maxHeight * 0.44,
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
                        final messageLayerTop = stageHeight * 0.52;
                        final messageLayerBottom =
                            _composerHeight + composerBottom + 12;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(child: stageShell),
                            ),
                            Positioned(
                              top: messageLayerTop,
                              left: 24,
                              right: 24,
                              bottom: messageLayerBottom,
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
                                      minHeight: math.max(
                                        stackConstraints.maxHeight -
                                            messageLayerTop -
                                            messageLayerBottom,
                                        1.0,
                                      ),
                                      padding: _messageLayerPadding,
                                      messages: _userMessages,
                                      includeKeys: true,
                                      allowOverflow: false,
                                    ),
                                  ),
                                ),
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
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else ...[
                  SizedBox(height: stageHeight, child: Center(child: stageShell)),
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
  const _UserMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF1F3726),
          fontWeight: FontWeight.w700,
          height: 1.24,
        ),
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
  final List<String> messages;
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

  final List<String> messages;
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
            text: messages[index],
          ),
          if (index != messages.length - 1)
            const SizedBox(height: _HomeScreenState._messageSpacing),
        ],
      ],
    );
  }
}

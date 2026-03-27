import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'メッセージ',
    this.readOnly = false,
    this.sendEnabled = false,
    this.onChanged,
    this.onSubmitted,
    this.onSendTap,
    this.onPhoneTap,
    this.onCameraTap,
    this.onImageTap,
    this.showPhoneAction = false,
    this.showMicAction = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool readOnly;
  final bool sendEnabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSendTap;
  final VoidCallback? onPhoneTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onImageTap;
  final bool showPhoneAction;
  final bool showMicAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderColor = Color(0xFF5A3727);
    const textColor = Color(0xFF352218);
    const shellColor = Color(0xFFF6E7CC);
    const fieldColor = Color(0xFFF3EBD8);
    const hintColor = Color(0xFF7A5A49);

    return NesContainer(
      key: const ValueKey<String>('chat-input-shell'),
      backgroundColor: shellColor.withValues(alpha: 0.92),
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      painterBuilder: NesContainerSquareCornerPainter.new,
      child: Row(
        children: [
          _ChatActionButton(
            key: ValueKey<String>('chat-input-camera'),
            icon: NesIcons.camera,
            tooltip: 'カメラ',
            onPressed: onCameraTap,
          ),
          _ChatActionButton(
            key: ValueKey<String>('chat-input-image'),
            icon: NesIcons.gallery,
            tooltip: '画像',
            onPressed: onImageTap,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fieldColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    key: const ValueKey<String>('chat-input-message-field'),
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: readOnly,
                    onTapOutside:
                        (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: hintColor,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showMicAction)
            _ChatActionButton(
              key: ValueKey<String>('chat-input-mic'),
              icon: NesIcons.audio,
              tooltip: 'マイク',
            ),
          if (showPhoneAction)
            _ChatActionButton(
              key: const ValueKey<String>('chat-input-phone'),
              icon: NesIcons.radio,
              tooltip: 'Homeで話す',
              onPressed: onPhoneTap,
            ),
          _SendActionButton(
            enabled: sendEnabled,
            onPressed: sendEnabled ? onSendTap : null,
          ),
        ],
      ),
    );
  }
}

class _ChatActionButton extends StatelessWidget {
  const _ChatActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final NesIconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF5A3727);

    return Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: NesIconButton(
            icon: icon,
            onPress: onPressed,
            size: const Size.square(24),
            primaryColor: borderColor,
            secondaryColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SendActionButton extends StatelessWidget {
  const _SendActionButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: NesButton.icon(
        key: const ValueKey<String>('chat-input-send'),
        type: enabled ? NesButtonType.primary : NesButtonType.normal,
        icon: enabled ? NesIcons.rightArrowIndicator : NesIcons.thinArrowRight,
        iconSize: const Size.square(18),
        buttonWidth: 28,
        onPressed: onPressed,
      ),
    );
  }
}

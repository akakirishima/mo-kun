import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

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
    final palette = AppearanceScope.paletteOf(context).chat;

    return Container(
      key: const ValueKey<String>('chat-input-shell'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: palette.composerShell.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.composerIcon.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.composerShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _ChatActionButton(
            key: ValueKey<String>('chat-input-camera'),
            icon: Icons.camera_alt_outlined,
            tooltip: 'カメラ',
            onPressed: onCameraTap,
          ),
          _ChatActionButton(
            key: ValueKey<String>('chat-input-image'),
            icon: Icons.photo_outlined,
            tooltip: '画像',
            onPressed: onImageTap,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                key: const ValueKey<String>('chat-input-message-field'),
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.composerHint,
                  ),
                  filled: true,
                  fillColor: palette.composerFieldFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.composerText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (showMicAction)
            const _ChatActionButton(
              key: ValueKey<String>('chat-input-mic'),
              icon: Icons.mic_none_rounded,
              tooltip: 'マイク',
            ),
          if (showPhoneAction)
            _ChatActionButton(
              key: const ValueKey<String>('chat-input-phone'),
              icon: Icons.call_outlined,
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

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;

    return IconButton(
      onPressed: onPressed ?? () {},
      icon: Icon(icon),
      iconSize: 22,
      color: palette.composerIcon,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      splashRadius: 20,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SendActionButton extends StatelessWidget {
  const _SendActionButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton.filled(
        key: const ValueKey<String>('chat-input-send'),
        onPressed: onPressed,
        tooltip: '送信',
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFFF7B4D0)
              : palette.composerHint.withValues(alpha: 0.28),
          foregroundColor: enabled
              ? const Color(0xFF6D3656)
              : palette.composerHint,
          disabledBackgroundColor: palette.composerHint.withValues(alpha: 0.28),
          disabledForegroundColor: palette.composerHint,
          minimumSize: const Size(42, 42),
        ),
        icon: const Icon(Icons.arrow_upward_rounded),
      ),
    );
  }
}

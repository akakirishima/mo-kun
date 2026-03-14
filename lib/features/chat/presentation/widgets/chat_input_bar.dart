import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key, required this.onPhoneTap});

  final VoidCallback onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).chat;

    return Container(
      key: const ValueKey<String>('chat-input-shell'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: palette.composerShell,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: palette.composerShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ChatActionButton(
            key: const ValueKey<String>('chat-input-camera'),
            icon: Icons.camera_alt_outlined,
            tooltip: 'カメラ',
          ),
          _ChatActionButton(
            key: const ValueKey<String>('chat-input-image'),
            icon: Icons.photo_outlined,
            tooltip: '画像',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                key: const ValueKey<String>('chat-input-message-field'),
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'メッセージ',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.composerHint,
                  ),
                  filled: true,
                  fillColor: palette.composerFieldFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.composerText,
                ),
              ),
            ),
          ),
          _ChatActionButton(
            key: const ValueKey<String>('chat-input-mic'),
            icon: Icons.mic_none_rounded,
            tooltip: 'マイク',
          ),
          _ChatActionButton(
            key: const ValueKey<String>('chat-input-phone'),
            icon: Icons.call_outlined,
            tooltip: 'Homeで話す',
            onPressed: onPhoneTap,
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

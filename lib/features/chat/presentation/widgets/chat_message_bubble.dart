import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    this.isCurrentUser = false,
    this.showAvatar = false,
    this.senderName,
    this.timestamp,
    this.statusLabel,
    this.alignmentKey,
    this.avatarKey,
  });
  final String text;
  final bool isCurrentUser;
  final bool showAvatar;
  final String? senderName;
  final String? timestamp;
  final String? statusLabel;
  final Key? alignmentKey;
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? palette.userBubbleFill
            : palette.characterBubbleFill,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isCurrentUser ? 18 : 6),
          bottomRight: Radius.circular(isCurrentUser ? 6 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.bubbleShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isCurrentUser ? palette.userText : palette.characterText,
          height: 1.35,
        ),
      ),
    );

    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              key: alignmentKey,
              alignment: Alignment.centerRight,
              child: bubble,
            ),
            if (statusLabel != null || timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusLabel != null)
                      Text(
                        statusLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.metaText,
                        ),
                      ),
                    if (statusLabel != null && timestamp != null)
                      const SizedBox(width: 4),
                    if (timestamp != null)
                      Text(
                        timestamp!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.metaText,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 20),
              child: _CharacterAvatar(key: avatarKey),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: Text(
                      senderName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.metaText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Align(
                  key: alignmentKey,
                  alignment: Alignment.centerLeft,
                  child: bubble,
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6),
                    child: Text(
                      timestamp!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.metaText),
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

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.avatarGradient,
        ),
        border: Border.all(color: palette.avatarBorder, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: palette.avatarText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

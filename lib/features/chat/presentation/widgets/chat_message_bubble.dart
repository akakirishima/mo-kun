import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    this.text,
    this.imagePath,
    this.imageKey,
    this.isCurrentUser = false,
    this.showAvatar = false,
    this.senderName,
    this.timestamp,
    this.statusLabel,
    this.alignmentKey,
    this.avatarKey,
  });
  final String? text;
  final String? imagePath;
  final Key? imageKey;
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
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final hasText = text != null && text!.isNotEmpty;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(
        horizontal: hasImage ? 8 : 14,
        vertical: hasImage ? 8 : 11,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            _ChatImageAttachment(
              key: imageKey,
              imagePath: imagePath!,
              isCurrentUser: isCurrentUser,
            ),
          if (hasImage && hasText) const SizedBox(height: 10),
          if (hasText)
            Text(
              text!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isCurrentUser ? palette.userText : palette.characterText,
                height: 1.35,
              ),
            ),
        ],
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
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: palette.avatarText,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatImageAttachment extends StatelessWidget {
  const _ChatImageAttachment({
    super.key,
    required this.imagePath,
    required this.isCurrentUser,
  });

  final String imagePath;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;
    final file = File(imagePath);
    final hasFile = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 188,
        height: 188,
        color: isCurrentUser
            ? palette.userBubbleFill.withValues(alpha: 0.42)
            : palette.characterBubbleFill.withValues(alpha: 0.42),
        child: hasFile
            ? Image.file(file, fit: BoxFit.cover)
            : _MissingChatImagePlaceholder(
                imagePath: imagePath,
                accentColor: isCurrentUser
                    ? palette.userText
                    : palette.metaText,
              ),
      ),
    );
  }
}

class _MissingChatImagePlaceholder extends StatelessWidget {
  const _MissingChatImagePlaceholder({
    required this.imagePath,
    required this.accentColor,
  });

  final String imagePath;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final filename = imagePath.split(RegExp(r'[\\/]')).last;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 42, color: accentColor),
          const SizedBox(height: 10),
          Text(
            filename,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

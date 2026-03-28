import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    this.text,
    this.imagePath,
    this.imageUrl,
    this.imageKey,
    this.isCurrentUser = false,
    this.showAvatar = false,
    this.senderName,
    this.timestamp,
    this.statusLabel,
    this.messageTypeLabel,
    this.alignmentKey,
    this.avatarKey,
  });

  final String? text;
  final String? imagePath;
  final String? imageUrl;
  final Key? imageKey;
  final bool isCurrentUser;
  final bool showAvatar;
  final String? senderName;
  final String? timestamp;
  final String? statusLabel;
  final String? messageTypeLabel;
  final Key? alignmentKey;
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) {
    const bubbleBorderColor = Color(0xFF5A3727);
    const bubbleTextColor = Color(0xFF352218);
    const characterFillColor = Color(0xFFF6E7CC);
    const userFillColor = Color(0xFFE6F0CC);
    const metaTextColor = Color(0xFF24150E);
    const errorMetaTextColor = Color(0xFF7A1F16);
    final hasImage =
        (imagePath != null && imagePath!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty);
    final hasText = text != null && text!.isNotEmpty;
    final bubble = Stack(
      clipBehavior: Clip.none,
      children: [
        NesContainer(
          backgroundColor: (isCurrentUser ? userFillColor : characterFillColor)
              .withValues(alpha: 0.92),
          borderColor: bubbleBorderColor,
          padding: EdgeInsets.symmetric(
            horizontal: hasImage ? 8 : 14,
            vertical: hasImage ? 8 : 11,
          ),
          painterBuilder: NesContainerSquareCornerPainter.new,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage)
                  _ChatImageAttachment(
                    key: imageKey,
                    imagePath: imagePath,
                    imageUrl: imageUrl,
                    isCurrentUser: isCurrentUser,
                  ),
                if (hasImage && hasText) const SizedBox(height: 10),
                if (hasText)
                  Text(
                    text!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: bubbleTextColor,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: isCurrentUser ? 14 : null,
          left: isCurrentUser ? null : 14,
          bottom: -10,
          child: _PixelTail(
            fillColor: isCurrentUser ? userFillColor : characterFillColor,
            borderColor: bubbleBorderColor,
            alignRight: isCurrentUser,
          ),
        ),
      ],
    );

    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              key: alignmentKey,
              alignment: Alignment.centerRight,
              child: bubble,
            ),
            if (statusLabel != null ||
                timestamp != null ||
                messageTypeLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (messageTypeLabel != null)
                      _MetaChip(
                        label: messageTypeLabel!,
                        textColor: metaTextColor,
                      ),
                    if (messageTypeLabel != null &&
                        (statusLabel != null || timestamp != null))
                      const SizedBox(width: 4),
                    if (statusLabel != null)
                      _MetaChip(
                        label: statusLabel!,
                        textColor: statusLabel == '送信失敗'
                            ? errorMetaTextColor
                            : metaTextColor,
                      ),
                    if (statusLabel != null && timestamp != null)
                      const SizedBox(width: 4),
                    if (timestamp != null)
                      _MetaChip(label: timestamp!, textColor: metaTextColor),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 24),
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
                        color: bubbleBorderColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Align(
                  key: alignmentKey,
                  alignment: Alignment.centerLeft,
                  child: bubble,
                ),
                if (timestamp != null || messageTypeLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (messageTypeLabel != null)
                          _MetaChip(
                            label: messageTypeLabel!,
                            textColor: metaTextColor,
                          ),
                        if (messageTypeLabel != null && timestamp != null)
                          const SizedBox(width: 4),
                        if (timestamp != null)
                          _MetaChip(
                            label: timestamp!,
                            textColor: metaTextColor,
                          ),
                      ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PixelTail extends StatelessWidget {
  const _PixelTail({
    required this.fillColor,
    required this.borderColor,
    required this.alignRight,
  });

  final Color fillColor;
  final Color borderColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      _TailSegment(
        width: 16,
        fillColor: fillColor.withValues(alpha: 0.18),
        borderColor: borderColor.withValues(alpha: 0.82),
      ),
      _TailSegment(
        width: 10,
        fillColor: fillColor.withValues(alpha: 0.18),
        borderColor: borderColor.withValues(alpha: 0.82),
      ),
      _TailSegment(
        width: 6,
        fillColor: fillColor.withValues(alpha: 0.18),
        borderColor: borderColor.withValues(alpha: 0.82),
      ),
    ];

    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: alignRight ? blocks.reversed.toList() : blocks,
    );
  }
}

class _TailSegment extends StatelessWidget {
  const _TailSegment({
    required this.width,
    required this.fillColor,
    required this.borderColor,
  });

  final double width;
  final Color fillColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    const avatarBorderColor = Color(0xFF5A3727);
    const avatarFillColor = Color(0xFFF6E7CC);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: avatarFillColor,
        border: Border.all(color: avatarBorderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: NesIcon(
        iconData: NesIcons.user,
        size: const Size.square(18),
        primaryColor: avatarBorderColor,
        secondaryColor: Colors.white,
      ),
    );
  }
}

class _ChatImageAttachment extends StatelessWidget {
  const _ChatImageAttachment({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.isCurrentUser,
  });

  final String? imagePath;
  final String? imageUrl;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final localPath = imagePath;
    final remoteUrl = imageUrl;
    final file = localPath == null ? null : File(localPath);
    final hasFile = file?.existsSync() ?? false;
    const bubbleBorderColor = Color(0xFF5A3727);
    const characterFillColor = Color(0xFFF6E7CC);
    const userFillColor = Color(0xFFE6F0CC);

    return Container(
      width: 188,
      height: 188,
      decoration: BoxDecoration(
        color: isCurrentUser ? userFillColor : characterFillColor,
        border: Border.all(color: bubbleBorderColor, width: 2),
      ),
      child: hasFile
          ? Image.file(file!, fit: BoxFit.cover)
          : (remoteUrl != null && remoteUrl.isNotEmpty)
          ? Image.network(remoteUrl, fit: BoxFit.cover)
          : _MissingChatImagePlaceholder(
              imagePath: localPath ?? remoteUrl ?? '',
              accentColor: bubbleBorderColor,
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
          NesIcon(
            iconData: NesIcons.gallery,
            size: const Size.square(28),
            primaryColor: accentColor,
            secondaryColor: Colors.white,
          ),
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

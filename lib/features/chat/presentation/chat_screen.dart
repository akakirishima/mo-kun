import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_message_bubble.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.onStartHomeCallTap,
    required this.onSettingsTap,
  });

  static const _composerBottomPadding =
      GlassBottomDock.reservedBottomSpacing + 8;

  final VoidCallback onStartHomeCallTap;
  final VoidCallback onSettingsTap;

  static const _messages = [
    _ChatMessageData(
      senderName: 'Mori',
      text: '今日の進み具合どう？ ちょっとだけでも聞かせて。',
      timestamp: '18:05',
      showAvatar: true,
    ),
    _ChatMessageData(
      isCurrentUser: true,
      text: 'いまUIを整えてる。チャット画面をLINEっぽくしたい。',
      timestamp: '18:06',
      statusLabel: '既読',
    ),
    _ChatMessageData(
      senderName: 'Mori',
      text: 'いいね。上を会話ヘッダーにして、下を操作バーっぽくすると近づくよ。',
      timestamp: '18:08',
      showAvatar: true,
    ),
    _ChatMessageData(
      isCurrentUser: true,
      text: 'メッセージは右、Moriは左、アイコン付きで進めるね。',
      timestamp: '18:10',
      statusLabel: '既読',
    ),
    _ChatMessageData(
      senderName: 'Mori',
      text: 'それで十分。まずは見た目を固めて、機能はあとからつなごう。',
      timestamp: '18:12',
      showAvatar: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).chat;
    final messages = _messages;

    return DecoratedBox(
      key: const ValueKey<String>('chat-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundTop, palette.backgroundBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          key: const ValueKey<String>('chat-screen'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                key: const ValueKey<String>('chat-top-bar'),
                children: [
                  Expanded(
                    child: Text(
                      'Mori',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.barIcon,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('chat-top-search'),
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    color: palette.barIcon,
                    tooltip: '会話を検索',
                  ),
                  IconButton(
                    key: const ValueKey<String>('chat-top-phone'),
                    onPressed: onStartHomeCallTap,
                    icon: const Icon(Icons.call_outlined),
                    color: palette.barIcon,
                    tooltip: 'Homeで話す',
                  ),
                  IconButton(
                    key: const ValueKey<String>('chat-settings-button'),
                    onPressed: onSettingsTap,
                    icon: const Icon(Icons.settings_outlined),
                    color: palette.barIcon,
                    tooltip: '設定',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('chat-message-list'),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                children: [
                  const _DateChip(label: '今日'),
                  ChatMessageBubble(
                    key: const ValueKey<String>('chat-message-character-1'),
                    alignmentKey: const ValueKey<String>(
                      'chat-message-character-align',
                    ),
                    avatarKey: const ValueKey<String>(
                      'chat-message-character-avatar',
                    ),
                    senderName: messages[0].senderName,
                    text: messages[0].text,
                    timestamp: messages[0].timestamp,
                    showAvatar: messages[0].showAvatar,
                  ),
                  ChatMessageBubble(
                    key: const ValueKey<String>('chat-message-user-1'),
                    alignmentKey: const ValueKey<String>(
                      'chat-message-user-align',
                    ),
                    text: messages[1].text,
                    timestamp: messages[1].timestamp,
                    statusLabel: messages[1].statusLabel,
                    isCurrentUser: true,
                  ),
                  ChatMessageBubble(
                    senderName: messages[2].senderName,
                    text: messages[2].text,
                    timestamp: messages[2].timestamp,
                    showAvatar: messages[2].showAvatar,
                  ),
                  ChatMessageBubble(
                    text: messages[3].text,
                    timestamp: messages[3].timestamp,
                    statusLabel: messages[3].statusLabel,
                    isCurrentUser: true,
                  ),
                  ChatMessageBubble(
                    senderName: messages[4].senderName,
                    text: messages[4].text,
                    timestamp: messages[4].timestamp,
                    showAvatar: messages[4].showAvatar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                _composerBottomPadding,
              ),
              child: ChatInputBar(
                key: const ValueKey<String>('chat-input-bar'),
                readOnly: true,
                showMicAction: true,
                showPhoneAction: true,
                onPhoneTap: onStartHomeCallTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: palette.dateChipFill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.dateChipText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChatMessageData {
  const _ChatMessageData({
    this.senderName,
    required this.text,
    this.timestamp,
    this.statusLabel,
    this.isCurrentUser = false,
    this.showAvatar = false,
  });

  final String? senderName;
  final String text;
  final String? timestamp;
  final String? statusLabel;
  final bool isCurrentUser;
  final bool showAvatar;
}

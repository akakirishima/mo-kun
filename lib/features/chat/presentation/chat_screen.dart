import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/widgets/glass_bottom_dock.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:image_picker/image_picker.dart';

typedef ChatImagePicker = Future<XFile?> Function(ImageSource source);

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.onStartHomeCallTap,
    required this.onSettingsTap,
    this.pickImage,
  });

  static const _composerBottomPadding =
      GlassBottomDock.reservedBottomSpacing + 8;

  final VoidCallback onStartHomeCallTap;
  final VoidCallback onSettingsTap;
  final ChatImagePicker? pickImage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _initialMessages = [
    _ChatEntry(
      senderName: 'Mori',
      text: '今日の進み具合どう？ ちょっとだけでも聞かせて。',
      timestamp: '18:05',
      showAvatar: true,
    ),
    _ChatEntry(
      isCurrentUser: true,
      text: 'いまUIを整えてる。チャット画面をLINEっぽくしたい。',
      timestamp: '18:06',
      statusLabel: '既読',
    ),
    _ChatEntry(
      senderName: 'Mori',
      text: 'いいね。上を会話ヘッダーにして、下を操作バーっぽくすると近づくよ。',
      timestamp: '18:08',
      showAvatar: true,
    ),
    _ChatEntry(
      isCurrentUser: true,
      text: 'メッセージは右、Moriは左、アイコン付きで進めるね。',
      timestamp: '18:10',
      statusLabel: '既読',
    ),
    _ChatEntry(
      senderName: 'Mori',
      text: 'それで十分。まずは見た目を固めて、機能はあとからつなごう。',
      timestamp: '18:12',
      showAvatar: true,
    ),
  ];

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final List<_ChatEntry> _messages;
  String _draftText = '';
  XFile? _pendingAttachment;
  bool _isPickingImage = false;

  bool get _canSend =>
      _draftText.trim().isNotEmpty || _pendingAttachment != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleInputChanged);
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _messages = List<_ChatEntry>.of(_initialMessages);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {
      _draftText = _controller.text;
    });
  }

  Future<XFile?> _pickImage(ImageSource source) {
    final picker = widget.pickImage;
    if (picker != null) {
      return picker(source);
    }

    return ImagePicker().pickImage(source: source, imageQuality: 85);
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
      if (!mounted) {
        return;
      }
      setState(() {
        _isPickingImage = false;
      });
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

  void _sendCurrentMessage() {
    final text = _draftText.trim();
    final attachment = _pendingAttachment;

    if (text.isEmpty && attachment == null) {
      return;
    }

    setState(() {
      if (attachment != null) {
        _messages.add(
          _ChatEntry(
            imagePath: attachment.path,
            isCurrentUser: true,
            timestamp: _timestampLabel(),
            statusLabel: '送信中',
          ),
        );
      }

      if (text.isNotEmpty) {
        _messages.add(
          _ChatEntry(
            text: text,
            isCurrentUser: true,
            timestamp: _timestampLabel(),
            statusLabel: '送信中',
          ),
        );
      }

      _controller.clear();
      _draftText = '';
      _pendingAttachment = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
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
    final theme = Theme.of(context);
    final palette = AppearanceScope.paletteOf(context).chat;
    var didAssignUserAlignKey = false;
    var didAssignCharacterAlignKey = false;
    var didAssignAvatarKey = false;

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
                    onPressed: widget.onStartHomeCallTap,
                    icon: const Icon(Icons.call_outlined),
                    color: palette.barIcon,
                    tooltip: 'Homeで話す',
                  ),
                  IconButton(
                    key: const ValueKey<String>('chat-settings-button'),
                    onPressed: widget.onSettingsTap,
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
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                children: [
                  const _DateChip(label: '今日'),
                  for (var index = 0; index < _messages.length; index++) ...[
                    Builder(
                      builder: (context) {
                        final message = _messages[index];
                        final alignmentKey = message.isCurrentUser
                            ? didAssignUserAlignKey
                                  ? null
                                  : const ValueKey<String>(
                                      'chat-message-user-align',
                                    )
                            : didAssignCharacterAlignKey
                            ? null
                            : const ValueKey<String>(
                                'chat-message-character-align',
                              );
                        final avatarKey =
                            message.showAvatar && !didAssignAvatarKey
                            ? const ValueKey<String>(
                                'chat-message-character-avatar',
                              )
                            : null;

                        if (message.isCurrentUser) {
                          didAssignUserAlignKey = true;
                        } else {
                          didAssignCharacterAlignKey = true;
                        }
                        if (avatarKey != null) {
                          didAssignAvatarKey = true;
                        }

                        return ChatMessageBubble(
                          key: ValueKey<String>('chat-message-$index'),
                          alignmentKey: alignmentKey,
                          avatarKey: avatarKey,
                          imageKey: message.imagePath != null
                              ? ValueKey<String>('chat-message-image-$index')
                              : null,
                          senderName: message.senderName,
                          text: message.text,
                          imagePath: message.imagePath,
                          timestamp: message.timestamp,
                          statusLabel: message.statusLabel,
                          isCurrentUser: message.isCurrentUser,
                          showAvatar: message.showAvatar,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (_pendingAttachment != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: _PendingAttachmentPreview(
                  attachment: _pendingAttachment!,
                  onRemove: _removePendingAttachment,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                ChatScreen._composerBottomPadding,
              ),
              child: ChatInputBar(
                key: const ValueKey<String>('chat-input-bar'),
                controller: _controller,
                focusNode: _focusNode,
                sendEnabled: _canSend,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendCurrentMessage(),
                onSendTap: _sendCurrentMessage,
                onCameraTap: () => _handleAttachmentTap(ImageSource.camera),
                onImageTap: () => _handleAttachmentTap(ImageSource.gallery),
                showMicAction: true,
                showPhoneAction: true,
                onPhoneTap: widget.onStartHomeCallTap,
              ),
            ),
          ],
        ),
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
    final palette = AppearanceScope.paletteOf(context).chat;

    return Container(
      key: const ValueKey<String>('chat-pending-preview'),
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
          _PendingAttachmentThumbnail(
            key: const ValueKey<String>('chat-pending-preview-image'),
            path: attachment.path,
          ),
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
            key: const ValueKey<String>('chat-pending-preview-remove'),
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

class _PendingAttachmentThumbnail extends StatelessWidget {
  const _PendingAttachmentThumbnail({super.key, required this.path});

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

class _ChatEntry {
  const _ChatEntry({
    this.senderName,
    this.text,
    this.imagePath,
    this.timestamp,
    this.statusLabel,
    this.isCurrentUser = false,
    this.showAvatar = false,
  });

  final String? senderName;
  final String? text;
  final String? imagePath;
  final String? timestamp;
  final String? statusLabel;
  final bool isCurrentUser;
  final bool showAvatar;
}

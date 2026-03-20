import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:gdgoc_2026_prototype/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_background_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nes_ui/nes_ui.dart';

typedef ChatImagePicker = Future<XFile?> Function(ImageSource source);
typedef ChatLostDataRetriever = Future<LostDataResponse> Function();

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.pickImage,
    this.retrieveLostData,
  });

  final ChatImagePicker? pickImage;
  final ChatLostDataRetriever? retrieveLostData;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _messageScrollController;
  final ImagePicker _imagePicker = ImagePicker();
  String _draftText = '';
  XFile? _pendingAttachment;
  bool _isPickingImage = false;

  bool get _canSend =>
      _draftText.trim().isNotEmpty || _pendingAttachment != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TextEditingController()..addListener(_handleInputChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _messageScrollController = ScrollController();
    _restoreLostAttachmentIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {
      _draftText = _controller.text;
    });
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _scrollMessagesToBottom();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_focusNode.hasFocus) {
      _scrollMessagesToBottom();
    }
  }

  Future<void> _restoreLostAttachmentIfNeeded() async {
    final shouldAttemptRestore =
        widget.retrieveLostData != null || Platform.isAndroid;
    if (!shouldAttemptRestore) {
      return;
    }

    final response = widget.retrieveLostData != null
        ? await widget.retrieveLostData!.call()
        : await _imagePicker.retrieveLostData();
    if (!mounted || response.isEmpty) {
      return;
    }

    final restoredFile = response.files?.isNotEmpty == true
        ? response.files!.first
        : response.file;
    if (restoredFile == null) {
      return;
    }

    setState(() {
      _pendingAttachment = restoredFile;
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
      final image = widget.pickImage != null
          ? await widget.pickImage!(source)
          : await _imagePicker.pickImage(source: source, imageQuality: 85);
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
    setState(() {
      _pendingAttachment = null;
    });
  }

  Future<void> _sendMessage() async {
    final message = _draftText.trim();
    final attachment = _pendingAttachment;
    if (message.isEmpty && attachment == null) {
      return;
    }

    setState(() {
      _controller.clear();
      _draftText = '';
      _pendingAttachment = null;
    });

    final session = await ref.read(sessionProvider.future);
    try {
      await ref
          .read(sendChatMessageControllerProvider)
          .send(
            session: session,
            text: message,
            imageBytes: attachment == null
                ? null
                : await attachment.readAsBytes(),
            imageMimeType: attachment == null
                ? null
                : _inferImageMimeTypeFromPath(attachment.path),
            imageFilename: attachment?.name,
            localImagePath: attachment?.path,
          );
    } catch (_) {}
    _scrollMessagesToBottom();
  }

  void _scrollMessagesToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }
      final target = _messageScrollController.position.maxScrollExtent;
      if (jump) {
        _messageScrollController.jumpTo(target);
        return;
      }
      _messageScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).chat;
    const panelBorderColor = Color(0xFF5A3727);
    const panelTextColor = Color(0xFF352218);
    const panelFillColor = Color(0xFFF6E7CC);
    final session = ref.watch(sessionProvider).valueOrNull;
    final backgroundPreference = session == null
        ? null
        : ref.watch(homeBackgroundPreferenceProvider(session.userId)).valueOrNull;
    final backgroundTheme = HomeBackgroundTheme.resolve(
      backgroundPreference?.themeId,
    );
    final customBackgroundUrl = backgroundPreference?.customImageUrl;
    final threadId = session?.threadId;
    final serverMessages = threadId == null
        ? const <ChatMessage>[]
        : ref.watch(chatMessagesProvider(threadId)).valueOrNull ??
              const <ChatMessage>[];
    if (threadId != null) {
      ref.listen<AsyncValue<List<ChatMessage>>>(
        chatMessagesProvider(threadId),
        (previous, next) {
          final resolvedClientIds =
              next.valueOrNull
                  ?.map((message) => message.clientMessageId)
                  .whereType<String>() ??
              const Iterable<String>.empty();
          ref
              .read(pendingMessagesProvider.notifier)
              .markCompleted(resolvedClientIds);
          _scrollMessagesToBottom();
        },
      );
    }
    final pendingMessages = threadId == null
        ? const <PendingChatMessage>[]
        : ref
              .watch(pendingMessagesProvider)
              .where((message) => message.threadId == threadId)
              .toList(growable: false);
    final timelineMessages = _buildTimelineMessages(
      serverMessages: serverMessages,
      pendingMessages: pendingMessages,
    );

    return DecoratedBox(
      key: const ValueKey<String>('chat-screen-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundTop, palette.backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child:
                (customBackgroundUrl != null && customBackgroundUrl.isNotEmpty)
                ? Image.network(
                    customBackgroundUrl,
                    key: const ValueKey<String>('chat-background-image'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => Image.asset(
                      backgroundTheme.backgroundAssetPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  )
                : Image.asset(
                    backgroundTheme.backgroundAssetPath,
                    key: const ValueKey<String>('chat-background-image'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: NesContainer(
                    backgroundColor: panelFillColor.withValues(alpha: 0.9),
                    borderColor: panelBorderColor,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    painterBuilder: NesContainerSquareCornerPainter.new,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Chat',
                            key: const ValueKey<String>('chat-screen'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: panelTextColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: panelFillColor,
                            border: Border.all(color: panelBorderColor, width: 2),
                          ),
                          child: Text(
                            '${timelineMessages.length}件',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: panelTextColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey<String>('chat-message-list'),
                    controller: _messageScrollController,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    itemCount: timelineMessages.length,
                    itemBuilder: (context, index) {
                      final entry = timelineMessages[index];
                      return _TimelineBubble(entry: entry);
                    },
                  ),
                ),
                if (_pendingAttachment != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: _PendingAttachmentPreview(
                      attachment: _pendingAttachment!,
                      onRemove: _removePendingAttachment,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  child: ChatInputBar(
                    key: const ValueKey<String>('chat-input-bar'),
                    controller: _controller,
                    focusNode: _focusNode,
                    sendEnabled: _canSend,
                    onChanged: (_) {},
                    onSubmitted: (_) => _sendMessage(),
                    onSendTap: _sendMessage,
                    onCameraTap: () => _handleAttachmentTap(ImageSource.camera),
                    onImageTap: () => _handleAttachmentTap(ImageSource.gallery),
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

class _TimelineBubble extends ConsumerWidget {
  const _TimelineBubble({required this.entry});

  final _ChatTimelineEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedImageUrl = ref.watch(resolvedImageUrlProvider(entry.imageUrl));
    return ChatMessageBubble(
      text: entry.text,
      imagePath: entry.localImagePath,
      imageUrl: resolvedImageUrl.valueOrNull,
      isCurrentUser: entry.isCurrentUser,
      showAvatar: !entry.isCurrentUser,
      senderName: entry.isCurrentUser ? null : 'Mori',
      timestamp: _formatTime(entry.createdAt),
      statusLabel: entry.statusLabel,
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
    return NesContainer(
      key: const ValueKey<String>('chat-pending-preview'),
      backgroundColor: const Color(0xFFF6E7CC).withValues(alpha: 0.92),
      borderColor: const Color(0xFF5A3727),
      padding: const EdgeInsets.all(10),
      painterBuilder: NesContainerSquareCornerPainter.new,
      child: Row(
        children: [
          _PendingAttachmentThumbnail(path: attachment.path),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachment.path.split(RegExp(r'[\\/]')).last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF352218),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          NesIconButton(
            key: const ValueKey<String>('chat-pending-preview-remove'),
            onPress: onRemove,
            icon: NesIcons.close,
            size: const Size.square(20),
          ),
        ],
      ),
    );
  }
}

class _PendingAttachmentThumbnail extends StatelessWidget {
  const _PendingAttachmentThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        height: 68,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : const Icon(Icons.image_outlined),
      ),
    );
  }
}

class _ChatTimelineEntry {
  const _ChatTimelineEntry({
    this.text,
    this.localImagePath,
    this.imageUrl,
    required this.createdAt,
    required this.isCurrentUser,
    this.statusLabel,
  });

  final String? text;
  final String? localImagePath;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isCurrentUser;
  final String? statusLabel;
}

List<_ChatTimelineEntry> _buildTimelineMessages({
  required List<ChatMessage> serverMessages,
  required List<PendingChatMessage> pendingMessages,
}) {
  final messages = <_ChatTimelineEntry>[
    for (final message in serverMessages)
      _ChatTimelineEntry(
        text: message.text.isEmpty ? null : message.text,
        imageUrl: message.imageUrl,
        createdAt: message.createdAt,
        isCurrentUser: message.role == ChatRole.user,
      ),
    for (final message in pendingMessages)
      _ChatTimelineEntry(
        text: message.text.isEmpty ? null : message.text,
        localImagePath: message.localImagePath,
        createdAt: message.createdAt,
        isCurrentUser: true,
        statusLabel: message.failed ? '送信失敗' : '送信中',
      ),
  ]..sort((left, right) => left.createdAt.compareTo(right.createdAt));
  return messages;
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? _inferImageMimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

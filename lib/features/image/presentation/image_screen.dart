import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key, required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  ConsumerState<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends ConsumerState<ImageScreen> {
  bool _isSubmitting = false;

  Future<void> _handleRegenerateTap() async {
    if (_isSubmitting) {
      return;
    }

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RegenerateImageSheet(),
    );

    if (!mounted || note == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(regenerateCharacterImageControllerProvider)
          .regenerate(reportText: note, title: '更新した姿');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('画像の再生成を開始しました')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('画像の再生成に失敗しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;
    final canPop = Navigator.canPop(context);
    final session = ref.watch(sessionProvider).valueOrNull;
    final characterId = session?.characterId;
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    final imageHistory = characterId == null
        ? const <CharacterImageVersion>[]
        : ref.watch(imageHistoryProvider(characterId)).valueOrNull ??
              const <CharacterImageVersion>[];
    final latestImageUrl = ref.watch(
      resolvedImageUrlProvider(character?.latestImageUrl),
    );

    return Scaffold(
      key: const ValueKey<String>('image-scaffold'),
      backgroundColor: palette.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey<String>('image-screen-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  key: const ValueKey<String>('image-screen'),
                  children: [
                    IconButton(
                      key: const ValueKey<String>('image-back-button'),
                      onPressed: canPop
                          ? () => Navigator.of(context).pop()
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: '戻る',
                      color: palette.settingsIcon,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.titleText,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '直近7日分の積み上がりから更新された姿',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.subtitleText),
                          ),
                        ],
                      ),
                    ),
                    if (!canPop)
                      IconButton(
                        key: const ValueKey<String>('image-settings-button'),
                        onPressed: widget.onSettingsTap,
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: '設定',
                        color: palette.settingsIcon,
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: _LatestImageCard(
                  character: character,
                  latestImageUrl: latestImageUrl,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  'Image History',
                  key: const ValueKey<String>('image-history-header'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.titleText,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 140),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = imageHistory[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ImageHistoryTile(item: item, index: index),
                  );
                }, childCount: imageHistory.length),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        key: const ValueKey<String>('image-post-fab'),
        onPressed: _isSubmitting ? null : _handleRegenerateTap,
        heroTag: 'image-post-fab',
        tooltip: '再生成',
        backgroundColor: palette.fabFill,
        foregroundColor: palette.fabForeground,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(Icons.refresh_rounded, size: 28),
      ),
    );
  }
}

class _RegenerateImageSheet extends StatefulWidget {
  const _RegenerateImageSheet();

  @override
  State<_RegenerateImageSheet> createState() => _RegenerateImageSheetState();
}

class _RegenerateImageSheetState extends State<_RegenerateImageSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          key: const ValueKey<String>('image-regenerate-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '再生成メモ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.titleText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '今回だけ反映したい雰囲気や補足を短く入れます。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.subtitleText),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey<String>('image-regenerate-input'),
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '少し春っぽい空気感にしたい、など',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey<String>('image-regenerate-submit'),
                  onPressed: () {
                    Navigator.of(context).pop(_controller.text.trim());
                  },
                  child: const Text('再生成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestImageCard extends StatelessWidget {
  const _LatestImageCard({
    required this.character,
    required this.latestImageUrl,
  });

  final CharacterSnapshot? character;
  final AsyncValue<String?> latestImageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;
    final status = switch (character?.imageStatus) {
      CharacterImageStatus.generating => '生成中',
      CharacterImageStatus.ready => '更新済み',
      CharacterImageStatus.failed => '失敗',
      _ => '未生成',
    };
    final subtitle = character == null
        ? 'オンボーディング完了後に最新ビジュアルが表示されます。'
        : '最終更新: ${character?.lastGeneratedAt?.toLocal().toString().substring(0, 16) ?? '未更新'}';

    return Container(
      key: const ValueKey<String>('image-latest-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4E3D4), Color(0xFFDAB5A4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            key: const ValueKey<String>('image-latest-media'),
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.38),
                ),
                child: latestImageUrl.when(
                  data: (resolvedUrl) {
                    if (resolvedUrl == null || resolvedUrl.isEmpty) {
                      return const _ImagePlaceholder(
                        icon: Icons.auto_awesome_rounded,
                        label: '最新画像はまだありません',
                        widgetKey: ValueKey<String>('image-latest-placeholder'),
                      );
                    }
                    return ColoredBox(
                      color: const Color(0xFFF7EEE8),
                      child: Center(
                        child: Image.network(
                          resolvedUrl,
                          key: const ValueKey<String>('image-latest-preview'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return const _ImagePlaceholder(
                              icon: Icons.broken_image_outlined,
                              label: '画像を読み込めませんでした',
                              widgetKey: ValueKey<String>('image-latest-error'),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      key: ValueKey<String>('image-latest-loading'),
                    ),
                  ),
                  error: (_, _) => const _ImagePlaceholder(
                    icon: Icons.broken_image_outlined,
                    label: '画像 URL の解決に失敗しました',
                    widgetKey: ValueKey<String>('image-latest-error'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            character?.name ?? 'Self',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: palette.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            key: const ValueKey<String>('image-latest-status'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.subtitleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.subtitleText),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.icon,
    required this.label,
    required this.widgetKey,
  });

  final IconData icon;
  final String label;
  final Key widgetKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        key: widgetKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.black54),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageHistoryTile extends ConsumerWidget {
  const _ImageHistoryTile({required this.item, required this.index});

  final CharacterImageVersion item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppearanceScope.paletteOf(context).image;
    final statusLabel = switch (item.status) {
      CharacterImageStatus.generating => '生成中',
      CharacterImageStatus.failed => '失敗',
      CharacterImageStatus.ready => '更新済み',
      _ => '未生成',
    };
    final resolvedImageUrl = ref.watch(resolvedImageUrlProvider(item.imageUrl));

    return Container(
      key: ValueKey<String>('image-history-item-$index'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 108,
              height: 72,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFCDA18A), Color(0xFFF0DED1)],
                  ),
                ),
                child: resolvedImageUrl.when(
                  data: (resolvedUrl) {
                    if (resolvedUrl == null || resolvedUrl.isEmpty) {
                      return const _HistoryThumbnailPlaceholder(
                        widgetKey: ValueKey<String>('image-history-placeholder'),
                      );
                    }
                    return ColoredBox(
                      color: const Color(0xFFF7EEE8),
                      child: Center(
                        child: Image.network(
                          resolvedUrl,
                          key: ValueKey<String>('image-history-preview-$index'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return const _HistoryThumbnailPlaceholder(
                              widgetKey: ValueKey<String>('image-history-error'),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, _) => const _HistoryThumbnailPlaceholder(
                    widgetKey: ValueKey<String>('image-history-error'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.titleText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.subtitleText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.promptExcerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.subtitleText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryThumbnailPlaceholder extends StatelessWidget {
  const _HistoryThumbnailPlaceholder({required this.widgetKey});

  final Key widgetKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.auto_awesome_rounded,
        key: widgetKey,
        color: Colors.black54,
      ),
    );
  }
}

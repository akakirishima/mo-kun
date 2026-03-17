import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';

class ImageScreen extends ConsumerWidget {
  const ImageScreen({super.key, required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppearanceScope.paletteOf(context).image;
    final session = ref.watch(sessionProvider).valueOrNull;
    final characterId = session?.characterId;
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    final imageHistory = characterId == null
        ? const <CharacterImageVersion>[]
        : ref.watch(imageHistoryProvider(characterId)).valueOrNull ??
              const <CharacterImageVersion>[];

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
                            '昨日の報告から更新された姿',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.subtitleText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('image-settings-button'),
                      onPressed: onSettingsTap,
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
                child: _LatestImageCard(character: character),
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
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('画像の手動再生成は backend 実装後に追加します')),
            );
        },
        heroTag: 'image-post-fab',
        tooltip: '再生成',
        backgroundColor: palette.fabFill,
        foregroundColor: palette.fabForeground,
        child: const Icon(Icons.refresh_rounded, size: 28),
      ),
    );
  }
}

class _LatestImageCard extends StatelessWidget {
  const _LatestImageCard({required this.character});

  final CharacterSnapshot? character;

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
          Text(
            character?.name ?? 'Mori',
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

class _ImageHistoryTile extends StatelessWidget {
  const _ImageHistoryTile({required this.item, required this.index});

  final CharacterImageVersion item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).image;
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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFCDA18A), Color(0xFFF0DED1)],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.titleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.promptExcerpt,
                  maxLines: 2,
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

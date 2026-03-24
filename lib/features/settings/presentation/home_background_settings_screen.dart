import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/home/presentation/home_background_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nes_ui/nes_ui.dart';

class HomeBackgroundSettingsScreen extends ConsumerStatefulWidget {
  const HomeBackgroundSettingsScreen({super.key, this.pickImage});

  final Future<XFile?> Function(ImageSource source)? pickImage;

  @override
  ConsumerState<HomeBackgroundSettingsScreen> createState() =>
      _HomeBackgroundSettingsScreenState();
}

class _HomeBackgroundSettingsScreenState
    extends ConsumerState<HomeBackgroundSettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _selectPreset(String themeId) async {
    try {
      await ref.read(homeBackgroundControllerProvider).selectTheme(themeId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HOME背景を更新しました。')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('背景の更新に失敗しました: $error')),
      );
    }
  }

  Future<void> _pickCustomBackground() async {
    if (_isUploading) {
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      final file = widget.pickImage != null
          ? await widget.pickImage!(ImageSource.gallery)
          : await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (!mounted || file == null) {
        return;
      }
      await ref
          .read(homeBackgroundControllerProvider)
          .uploadCustomImage(
            imageBytes: await file.readAsBytes(),
            imageMimeType: _inferImageMimeTypeFromPath(file.path),
            imageFilename: file.name,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カスタム背景を保存しました。')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の保存に失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;
    final session = ref.watch(sessionProvider).valueOrNull;
    final preference = session == null
        ? null
        : ref.watch(homeBackgroundPreferenceProvider(session.userId)).valueOrNull;
    final selectedTheme = HomeBackgroundTheme.resolve(preference?.themeId);
    final customImageUrl = preference?.customImageUrl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.backgroundTop, palette.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            key: const ValueKey<String>('home-background-settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    NesButton.icon(
                      key: const ValueKey<String>(
                        'home-background-settings-back-button',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      type: NesButtonType.normal,
                      icon: NesIcons.leftArrowIndicator,
                      iconSize: const Size.square(18),
                      buttonWidth: 28,
                    ),
                    Expanded(
                      child: Text(
                        'HOME背景',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.headerText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  children: [
                    NesContainer(
                      key: const ValueKey<String>('home-background-preview-card'),
                      label: '現在の背景',
                      backgroundColor: palette.sectionCard,
                      borderColor: palette.sectionTitle,
                      padding: const EdgeInsets.all(18),
                      painterBuilder: NesContainerSquareCornerPainter.new,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: customImageUrl != null &&
                                      customImageUrl.isNotEmpty
                                  ? Image.network(
                                      customImageUrl,
                                      key: const ValueKey<String>(
                                        'home-background-preview-image',
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        selectedTheme.backgroundAssetPath,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      selectedTheme.backgroundAssetPath,
                                      key: const ValueKey<String>(
                                        'home-background-preview-image',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            customImageUrl != null && customImageUrl.isNotEmpty
                                ? 'カスタム画像'
                                : selectedTheme.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.tileTitle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customImageUrl != null && customImageUrl.isNotEmpty
                                ? '端末から選んだ画像をHOME背景に使います。'
                                : selectedTheme.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.tileSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    NesContainer(
                      label: 'プリセット',
                      backgroundColor: palette.sectionCard,
                      borderColor: palette.sectionTitle,
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
                      painterBuilder: NesContainerSquareCornerPainter.new,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          children: [
                            for (final theme in HomeBackgroundTheme.values)
                              _BackgroundPresetTile(
                                theme: theme,
                                isSelected:
                                    (customImageUrl == null ||
                                        customImageUrl.isEmpty) &&
                                    selectedTheme.id == theme.id,
                                onTap: () => _selectPreset(theme.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    NesContainer(
                      label: 'カスタム画像',
                      backgroundColor: palette.sectionCard,
                      borderColor: palette.sectionTitle,
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                      painterBuilder: NesContainerSquareCornerPainter.new,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '端末から選んだ画像を Firebase に保存して使います。',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: palette.tileSubtitle,
                              ),
                            ),
                            const SizedBox(height: 14),
                            NesButton(
                              key: const ValueKey<String>(
                                'home-background-upload-button',
                              ),
                              type: NesButtonType.primary,
                              onPressed: _isUploading ? null : _pickCustomBackground,
                              child: Text(_isUploading ? 'アップロード中...' : '画像を選ぶ'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundPresetTile extends StatelessWidget {
  const _BackgroundPresetTile({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final HomeBackgroundTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NesPressable(
        key: ValueKey<String>('home-background-preset-${theme.id}'),
        onPress: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.tileIconChipFill.withValues(alpha: 0.42),
            border: Border.all(
              color: isSelected ? palette.sectionTitle : palette.tileIconColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  theme.backgroundAssetPath,
                  width: 54,
                  height: 78,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.tileTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.tileSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: NesIcon(
                  iconData: NesIcons.check,
                  size: const Size.square(20),
                  primaryColor: palette.sectionTitle,
                  secondaryColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _inferImageMimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

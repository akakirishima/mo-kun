import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:nes_ui/nes_ui.dart';

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  ConsumerState<VoiceSettingsScreen> createState() =>
      _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  String? _selectedVoiceName;
  bool _isSaving = false;

  void _seed(AssistantVoicePreference? preference) {
    _selectedVoiceName ??= preference?.voiceName ?? defaultAssistantVoiceName;
  }

  Future<void> _save() async {
    final voiceName = _selectedVoiceName;
    if (_isSaving || voiceName == null) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref.read(assistantVoiceSettingsControllerProvider).save(voiceName);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('音声を $voiceName に保存しました')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
        : ref
              .watch(assistantVoicePreferenceProvider(session.userId))
              .valueOrNull;
    _seed(preference);

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
            key: const ValueKey<String>('voice-settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    NesButton.icon(
                      key: const ValueKey<String>('voice-settings-back-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      type: NesButtonType.normal,
                      icon: NesIcons.leftArrowIndicator,
                      iconSize: const Size.square(18),
                      buttonWidth: 28,
                    ),
                    Expanded(
                      child: Text(
                        'AI音声',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                      label: '声を選ぶ',
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
                              '通常の音声返信とリアルタイム会話の両方に使われます。',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: palette.tileSubtitle,
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: palette.tileIconChipFill.withValues(
                                  alpha: 0.45,
                                ),
                                border: Border.all(
                                  color: palette.tileIconColor,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '現在の保存状態',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: palette.tileTitle,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '現在の保存値: ${preference?.voiceName ?? defaultAssistantVoiceName}',
                                    key: const ValueKey<String>(
                                      'voice-settings-current-voice',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: palette.tileSubtitle,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final option in assistantVoiceOptions) ...[
                              _VoiceOptionTile(
                                option: option,
                                selected:
                                    _selectedVoiceName == option.voiceName,
                                onTap: () {
                                  setState(() {
                                    _selectedVoiceName = option.voiceName;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                            NesButton(
                              key: const ValueKey<String>(
                                'voice-settings-save-button',
                              ),
                              type: NesButtonType.primary,
                              onPressed: _isSaving ? null : _save,
                              child: Text(_isSaving ? '保存中...' : '保存する'),
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

class _VoiceOptionTile extends StatelessWidget {
  const _VoiceOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AssistantVoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;
    final borderColor = selected ? palette.sectionTitle : palette.tileIconColor;
    final fillColor = selected
        ? palette.tileIconChipFill.withValues(alpha: 0.72)
        : palette.tileIconChipFill.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      child: NesPressable(
        key: ValueKey<String>('voice-option-${option.voiceName}'),
        onPress: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: borderColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.tileTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.tileSubtitle,
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

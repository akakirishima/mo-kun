import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:nes_ui/nes_ui.dart';

class CharacterSettingsScreen extends ConsumerStatefulWidget {
  const CharacterSettingsScreen({super.key});

  @override
  ConsumerState<CharacterSettingsScreen> createState() =>
      _CharacterSettingsScreenState();
}

class _CharacterSettingsScreenState
    extends ConsumerState<CharacterSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _greetingController;
  late final TextEditingController _personaController;
  bool _didSeed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _greetingController = TextEditingController();
    _personaController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _greetingController.dispose();
    _personaController.dispose();
    super.dispose();
  }

  void _seed(CharacterSnapshot? character) {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    _nameController.text = character?.name ?? '';
    _greetingController.text = character?.starterGreeting ?? '';
    _personaController.text = character?.personaPrompt ?? '';
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref.read(characterSettingsControllerProvider).save(
        CharacterSettings(
          name: _nameController.text.trim(),
          starterGreeting: _greetingController.text.trim(),
          personaPrompt: _personaController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
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
    final characterId = session?.characterId;
    final character = characterId == null
        ? null
        : ref.watch(characterProvider(characterId)).valueOrNull;
    _seed(character);

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
            key: const ValueKey<String>('character-settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    NesButton.icon(
                      key: const ValueKey<String>(
                        'character-settings-back-button',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      type: NesButtonType.normal,
                      icon: NesIcons.leftArrowIndicator,
                      iconSize: const Size.square(18),
                      buttonWidth: 28,
                    ),
                    Expanded(
                      child: Text(
                        'AI / キャラクター',
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
                      label: 'キャラクター設定',
                      backgroundColor: palette.sectionCard,
                      borderColor: palette.sectionTitle,
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                      painterBuilder: NesContainerSquareCornerPainter.new,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'character-settings-name',
                              ),
                              controller: _nameController,
                              label: 'キャラクター名',
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'character-settings-greeting',
                              ),
                              controller: _greetingController,
                              label: '最初のひとこと',
                              minLines: 2,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'character-settings-persona',
                              ),
                              controller: _personaController,
                              label: '反応の方針',
                              minLines: 4,
                              maxLines: 6,
                            ),
                            const SizedBox(height: 16),
                            NesButton(
                              key: const ValueKey<String>(
                                'character-settings-save-button',
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

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: palette.tileTitle,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:nes_ui/nes_ui.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _goalController;
  late final TextEditingController _partnerStyleController;
  late final TextEditingController _weakPointsController;
  CharacterGender _selectedGender = CharacterGender.nonBinary;
  bool _didSeed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _ageController = TextEditingController();
    _goalController = TextEditingController();
    _partnerStyleController = TextEditingController();
    _weakPointsController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _goalController.dispose();
    _partnerStyleController.dispose();
    _weakPointsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final preset = AppearanceScope.controllerOf(context).preset;
      await ref.read(userProfileControllerProvider).save(
        UserProfileInput(
          displayName: _displayNameController.text.trim(),
          goal: _goalController.text.trim(),
          partnerStyle: _partnerStyleController.text.trim(),
          weakPoints: _weakPointsController.text
              .split(RegExp(r'[\n,]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          age: age,
          characterGender: _selectedGender,
          appearancePreset: preset,
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

  void _seed(UserProfileInput? profile) {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    _displayNameController.text = profile?.displayName ?? '';
    _ageController.text = profile?.age.toString() ?? '';
    _goalController.text = profile?.goal ?? '';
    _partnerStyleController.text = profile?.partnerStyle ?? '';
    _weakPointsController.text = profile?.weakPoints.join('\n') ?? '';
    _selectedGender = profile?.characterGender ?? CharacterGender.nonBinary;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;
    final session = ref.watch(sessionProvider).valueOrNull;
    final profile = session == null
        ? null
        : ref.watch(userProfileProvider(session.userId)).valueOrNull;
    _seed(profile);

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
            key: const ValueKey<String>('profile-settings-screen'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    NesButton.icon(
                      key: const ValueKey<String>('profile-settings-back-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      type: NesButtonType.normal,
                      icon: NesIcons.leftArrowIndicator,
                      iconSize: const Size.square(18),
                      buttonWidth: 28,
                    ),
                    Expanded(
                      child: Text(
                        'プロフィール',
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
                      label: '基本情報',
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
                                'profile-settings-display-name',
                              ),
                              controller: _displayNameController,
                              label: '表示名',
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'profile-settings-age',
                              ),
                              controller: _ageController,
                              label: '年齢',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _GenderField(
                              value: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'profile-settings-goal',
                              ),
                              controller: _goalController,
                              label: '目標',
                              minLines: 2,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'profile-settings-partner-style',
                              ),
                              controller: _partnerStyleController,
                              label: '伴走スタイル',
                              minLines: 2,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _SettingsField(
                              fieldKey: const ValueKey<String>(
                                'profile-settings-weak-points',
                              ),
                              controller: _weakPointsController,
                              label: '気になる点',
                              hintText: '改行かカンマ区切りで入力',
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 16),
                            NesButton(
                              key: const ValueKey<String>(
                                'profile-settings-save-button',
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
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

  final CharacterGender value;
  final ValueChanged<CharacterGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '見た目の性別',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: palette.tileTitle,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<CharacterGender>(
          value: value,
          items:
              CharacterGender.values
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender.label),
                    ),
                  )
                  .toList(growable: false),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

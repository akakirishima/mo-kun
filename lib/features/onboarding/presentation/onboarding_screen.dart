import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _displayNameController = TextEditingController();
  final _goalController = TextEditingController();
  final _partnerStyleController = TextEditingController();
  final _weakPointsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _goalController.dispose();
    _partnerStyleController.dispose();
    _weakPointsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(onboardingControllerProvider)
          .submit(
            UserProfileInput(
              displayName: _displayNameController.text.trim(),
              goal: _goalController.text.trim(),
              partnerStyle: _partnerStyleController.text.trim(),
              weakPoints: _weakPointsController.text
                  .split('、')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false),
            ),
          );
    } catch (error) {
      setState(() {
        _errorMessage = 'キャラクター生成に失敗しました。少し待ってから再試行してください。';
      });
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
    final theme = Theme.of(context);
    final canSubmit =
        _displayNameController.text.trim().isNotEmpty &&
        _goalController.text.trim().isNotEmpty &&
        _partnerStyleController.text.trim().isNotEmpty &&
        !_isSubmitting;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3F8), Color(0xFFF8ECE1), Color(0xFFF4F6FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'はじめに、あなたのことを教えてください',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'プロフィールから相棒の性格と最初のビジュアルを組み立てます。',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _FieldBlock(
                          label: '呼ばれたい名前',
                          controller: _displayNameController,
                          hintText: '例: やまだ',
                          onChanged: (_) => setState(() {}),
                        ),
                        _FieldBlock(
                          label: 'いま頑張りたいこと',
                          controller: _goalController,
                          hintText: '例: 筋トレを習慣化したい',
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                        ),
                        _FieldBlock(
                          label: '相棒にどう接してほしいか',
                          controller: _partnerStyleController,
                          hintText: '例: やさしく背中を押してほしい',
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                        ),
                        _FieldBlock(
                          label: '苦手なこと',
                          controller: _weakPointsController,
                          hintText: '例: 継続、朝起きること、食事管理',
                          maxLines: 2,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey<String>('onboarding-submit'),
                            onPressed: canSubmit ? _submit : null,
                            child: Text(
                              _isSubmitting ? '生成中...' : 'キャラクターを作成する',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

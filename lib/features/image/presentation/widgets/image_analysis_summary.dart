import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/widgets/section_card.dart';

class ImageAnalysisSummary extends StatelessWidget {
  const ImageAnalysisSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Analysis to record',
      description:
          'The future API result can land here before the user confirms it.',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine(label: 'Detected context', value: 'Desk study session'),
          SizedBox(height: 10),
          _SummaryLine(label: 'Suggested tag', value: 'Focus'),
          SizedBox(height: 10),
          _SummaryLine(label: 'Record target', value: 'Today log'),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/widgets/section_card.dart';

class StatusSummaryCard extends StatelessWidget {
  const StatusSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Today\'s rhythm',
      description:
          'A quick read on how the character is doing before you send input.',
      child: Row(
        children: const [
          Expanded(
            child: _StatusTile(
              label: 'Energy',
              value: '78%',
              tone: Color(0xFF52B788),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatusTile(
              label: 'Focus',
              value: 'High',
              tone: Color(0xFF40916C),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatusTile(
              label: 'Mood',
              value: 'Warm',
              tone: Color(0xFFDDA15E),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(color: tone)),
        ],
      ),
    );
  }
}

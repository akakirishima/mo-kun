import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.description,
    required this.child,
  });

  final String? title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NesContainer(
      label: title,
      backgroundColor: Colors.white,
      borderColor: theme.colorScheme.onSurface,
      padding: const EdgeInsets.all(20),
      painterBuilder: NesContainerSquareCornerPainter.new,
      child: Padding(
        padding: EdgeInsets.only(top: title == null ? 0 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

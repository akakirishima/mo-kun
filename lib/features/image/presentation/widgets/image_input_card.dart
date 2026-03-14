import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/widgets/section_card.dart';

class ImageInputCard extends StatelessWidget {
  const ImageInputCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Add an image',
      description:
          'Use this mode when a photo helps the record more than text.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Open gallery'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Use camera'),
          ),
        ],
      ),
    );
  }
}

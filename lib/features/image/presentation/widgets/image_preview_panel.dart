import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/widgets/section_card.dart';

class ImagePreviewPanel extends StatelessWidget {
  const ImagePreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Preview',
      description:
          'A placeholder canvas for the selected image before analysis starts.',
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9F5DB), Color(0xFFFDF0D5)],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search_rounded, size: 56),
            SizedBox(height: 12),
            Text('Image preview placeholder'),
          ],
        ),
      ),
    );
  }
}

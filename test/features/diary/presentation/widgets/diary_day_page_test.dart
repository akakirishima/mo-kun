import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdgoc_2026_prototype/core/app/app_providers.dart';
import 'package:gdgoc_2026_prototype/core/app/image_url_resolver.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_page.dart';

import '../../../../test_support/fake_app.dart';
import '../../../../test_support/mock_network_images.dart';

class _FakeImageUrlResolver extends ImageUrlResolver {
  _FakeImageUrlResolver(this.mapping);

  final Map<String, String> mapping;

  @override
  Future<String?> resolve(String? rawUrl) async {
    if (rawUrl == null) {
      return null;
    }
    return mapping[rawUrl] ?? rawUrl;
  }
}

void main() {
  DiaryDayEntry buildEntry({String? imageUrl}) {
    return DiaryDayEntry(
      dayNumber: 3,
      weekdayLabel: 'げつ',
      body: '今日は少し進めた。',
      illustrationPalette: const [
        Color(0xFFEFC7A9),
        Color(0xFFDE8F73),
        Color(0xFFF9E4A6),
      ],
      highlightLabel: '小さく前進した日',
      imageUrl: imageUrl,
    );
  }

  testWidgets('renders a resolved diary image when available', (
    WidgetTester tester,
  ) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        wrapWithTestApp(
          child: DiaryDayPage(
            entry: buildEntry(imageUrl: 'https://example.com/today.png'),
            monthNumber: '3',
            bottomClearance: 80,
          ),
          overrides: [
            imageUrlResolverProvider.overrideWithValue(
              _FakeImageUrlResolver(const {
                'https://example.com/today.png': 'https://example.com/today.png',
              }),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const ValueKey<String>('diary-entry-image-3')),
        findsOneWidget,
      );
      final image = tester.widget<Image>(
        find.byKey(const ValueKey<String>('diary-entry-image-3')),
      );
      expect(image.fit, BoxFit.contain);
    });
  });

  testWidgets('falls back to the sketch placeholder without a diary image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        child: DiaryDayPage(
          entry: buildEntry(),
          monthNumber: '3',
          bottomClearance: 80,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey<String>('diary-entry-image-placeholder-3')),
      findsOneWidget,
    );
  });
}

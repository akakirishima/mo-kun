import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fake_app.dart';

void main() {
  test(
    'groups recorded diary summaries into shelf books in descending order',
    () async {
      final repository = buildFakeRepository();
      addTearDown(repository.dispose);

      final books = await repository
          .watchDiaryShelfBooks(userId: 'test-user')
          .first;
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1);

      expect(books, hasLength(2));
      expect(books.first.monthStart, DateTime(now.year, now.month));
      expect(books.first.recordedDaysCount, 2);
      expect(
        books.last.monthStart,
        DateTime(previousMonth.year, previousMonth.month),
      );
      expect(books.last.recordedDaysCount, 1);
    },
  );
}

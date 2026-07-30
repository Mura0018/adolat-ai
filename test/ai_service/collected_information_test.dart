import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/workflow/collected_information.dart';

void main() {
  group('CollectedInformation.has', () {
    test('is false for an absent key', () {
      const collected = CollectedInformation();

      expect(collected.has('complaint_target'), isFalse);
    });

    test('is false for an empty or whitespace-only answer', () {
      const collected = CollectedInformation(entries: {'a': '', 'b': '   '});

      expect(collected.has('a'), isFalse);
      expect(collected.has('b'), isFalse);
      expect(collected.filledCount, 0);
      expect(collected.isEmpty, isTrue);
    });

    test('is true for a non-empty answer', () {
      const collected = CollectedInformation(entries: {'a': 'javob'});

      expect(collected.has('a'), isTrue);
      expect(collected.filledCount, 1);
    });
  });

  group('CollectedInformation.withEntry', () {
    test('returns a new instance and leaves the original untouched', () {
      const original = CollectedInformation();

      final updated = original.withEntry('a', 'javob');

      expect(original.has('a'), isFalse);
      expect(updated.has('a'), isTrue);
      expect(updated.valueFor('a'), 'javob');
    });

    test('overwrites an existing answer -- the user may correct themselves', () {
      const original = CollectedInformation(entries: {'a': 'eski'});

      final updated = original.withEntry('a', 'yangi');

      expect(updated.valueFor('a'), 'yangi');
      expect(updated.filledCount, 1);
    });
  });

  group('CollectedInformation equality', () {
    test('two instances with the same entries are equal regardless of insert order', () {
      final first = const CollectedInformation().withEntry('a', '1').withEntry('b', '2');
      final second = const CollectedInformation().withEntry('b', '2').withEntry('a', '1');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('differs when a value differs', () {
      const first = CollectedInformation(entries: {'a': '1'});
      const second = CollectedInformation(entries: {'a': '2'});

      expect(first, isNot(second));
    });
  });

  group('CollectedInformation.toString', () {
    test('never includes answer values or requirement keys', () {
      const collected = CollectedInformation(
        entries: {'complaint_target': 'juda maxfiy shaxsiy tafsilot'},
      );

      final text = collected.toString();

      expect(text.contains('juda maxfiy shaxsiy tafsilot'), isFalse);
      expect(text.contains('complaint_target'), isFalse);
      expect(text.contains('1'), isTrue); // faqat soni
    });
  });
}

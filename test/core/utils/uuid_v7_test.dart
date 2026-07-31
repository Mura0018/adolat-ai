import 'dart:math';

import 'package:adolat_ai/core/utils/uuid_v7.dart';
import 'package:flutter_test/flutter_test.dart';

/// UUID v7 generatori RFC 9562 ga mos ekanini qulflaydi.
///
/// **Nega bu testlar batafsil:** ADR-009 paket o'rniga o'z
/// implementatsiyasini tanlashga ruxsat berdi, lekin shart bilan —
/// to'g'rilik testlar bilan kafolatlansin. Identifikator butun
/// ma'lumotlar bazasining kaliti, shuning uchun versiya/variant
/// bitidagi xato ham jimgina noto'g'ri ma'lumotga olib kelardi.
void main() {
  group('format (RFC 9562)', () {
    test('kanonik 8-4-4-4-12 shaklda', () {
      final id = UuidV7.generate();

      expect(UuidV7.isValid(id), isTrue, reason: id);
      expect(id.length, 36);
      expect(id.split('-').map((p) => p.length), [8, 4, 4, 4, 12]);
    });

    test('versiya raqami 7', () {
      for (var i = 0; i < 50; i++) {
        final id = UuidV7.generate();
        // 13-belgi (0-indeks) -- versiya nibble'i.
        expect(id[14], '7', reason: id);
      }
    });

    test('variant bitlari RFC 4122/9562 ga mos (8, 9, a yoki b)', () {
      for (var i = 0; i < 50; i++) {
        final id = UuidV7.generate();
        expect(['8', '9', 'a', 'b'], contains(id[19]), reason: id);
      }
    });

    test('faqat kichik harfli o\'n oltilik belgilar', () {
      final id = UuidV7.generate();

      expect(id, id.toLowerCase());
    });
  });

  group('vaqt tamg\'asi (tartiblanish asosi)', () {
    test('berilgan vaqt identifikatorga yoziladi', () {
      final moment = DateTime.utc(2026, 7, 31, 12, 34, 56);

      final id = UuidV7.generate(now: moment);

      expect(UuidV7.timestampOf(id), moment);
    });

    test('kechroq yaratilgan id LEKSIKOGRAFIK jihatdan kattaroq', () {
      // Bu -- v7 ning butun ma'nosi: matn bo'yicha saralash
      // yaratilish tartibiga mos keladi, ya'ni indeks lokalligi va
      // keyset-pagination ishlaydi.
      final early = UuidV7.generate(now: DateTime.utc(2026, 1, 1));
      final middle = UuidV7.generate(now: DateTime.utc(2026, 6, 1));
      final late = UuidV7.generate(now: DateTime.utc(2026, 12, 1));

      final sorted = [late, early, middle]..sort();

      expect(sorted, [early, middle, late]);
    });

    test('ketma-ket yaratilgan identifikatorlar tartibni buzmaydi', () async {
      final first = UuidV7.generate();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = UuidV7.generate();

      expect(first.compareTo(second), lessThan(0));
    });

    test('noto\'g\'ri matn uchun timestampOf null qaytaradi', () {
      expect(UuidV7.timestampOf('salom-dunyo'), isNull);
      expect(UuidV7.timestampOf(''), isNull);
    });
  });

  group('noyoblik', () {
    test('10 000 ta identifikator takrorlanmaydi', () {
      final ids = <String>{};
      for (var i = 0; i < 10000; i++) {
        ids.add(UuidV7.generate());
      }

      expect(ids, hasLength(10000));
    });

    test('AYNI millisekundda ham takrorlanmaydi', () {
      // Vaqt tamg'asi bir xil bo'lsa, farq faqat 74 bit tasodifiy
      // qismda qoladi -- shu holat alohida tekshiriladi.
      final moment = DateTime.utc(2026, 7, 31);
      final ids = <String>{};
      for (var i = 0; i < 1000; i++) {
        ids.add(UuidV7.generate(now: moment));
      }

      expect(ids, hasLength(1000));
    });
  });

  group('tasodifiylik manbai', () {
    test('berilgan manba ishlatiladi (test uchun determinizm)', () {
      final first = UuidV7.generate(now: DateTime.utc(2026), random: Random(42));
      final second = UuidV7.generate(now: DateTime.utc(2026), random: Random(42));

      expect(first, second);
    });

    test('turli urug\' (seed) turli natija beradi', () {
      final first = UuidV7.generate(now: DateTime.utc(2026), random: Random(1));
      final second = UuidV7.generate(now: DateTime.utc(2026), random: Random(2));

      expect(first, isNot(second));
    });
  });

  group('isValid', () {
    test('haqiqiy identifikatorni qabul qiladi', () {
      expect(UuidV7.isValid(UuidV7.generate()), isTrue);
    });

    test('noto\'g\'ri shakllarni rad etadi', () {
      const invalid = [
        '',
        'salom',
        '0189d6e2-0000-7000-8000',
        '0189d6e2000070008000000000000000',
        '0189D6E2-0000-7000-8000-000000000000', // katta harf
        '0189d6e2-0000-7000-8000-00000000000g', // g -- hex emas
      ];

      for (final value in invalid) {
        expect(UuidV7.isValid(value), isFalse, reason: value);
      }
    });
  });
}

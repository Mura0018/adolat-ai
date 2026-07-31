import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seriyalash — doimiylik (persistence) talabining o'zagi: bularsiz
/// navbat ilova qayta ochilganda tiklanmaydi (Module 6C).
void main() {
  final operation = PendingOperation(
    id: 'op-1',
    kind: PendingOperationKind.uploadAttachment,
    entityType: 'attachment',
    entityId: 'file-1',
    payload: const {'path': '/tmp/file.pdf', 'size': 1024},
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    status: PendingOperationStatus.failed,
    attemptCount: 3,
    lastAttemptAt: DateTime.utc(2026, 1, 2, 4),
    lastError: 'tarmoq uzildi',
    dependsOnOperationId: 'op-parent',
  );

  group('toJson/fromJson', () {
    test('to\'liq aylanma (round trip) hech narsani yo\'qotmaydi', () {
      final restored = PendingOperation.fromJson(operation.toJson());

      expect(restored, operation);
      expect(restored.payload, operation.payload);
      expect(restored.lastError, 'tarmoq uzildi');
      expect(restored.dependsOnOperationId, 'op-parent');
    });

    test('idempotentlik kaliti aylanmadan keyin ham o\'zgarmaydi', () {
      // Agar `id` saqlanmasa, qayta yuborilgan amal serverda TAKRORIY
      // yozuv hosil qilardi -- doimiylikning eng xavfli xatosi.
      expect(PendingOperation.fromJson(operation.toJson()).id, 'op-1');
    });

    test('ixtiyoriy maydonlarsiz amal ham aylanadi', () {
      final minimal = PendingOperation(
        id: 'op-2',
        kind: PendingOperationKind.createRecord,
        entityType: 'appeal',
        entityId: 'appeal-1',
        payload: const {},
        createdAt: DateTime.utc(2026),
      );

      final restored = PendingOperation.fromJson(minimal.toJson());

      expect(restored, minimal);
      expect(restored.lastAttemptAt, isNull);
      expect(restored.lastError, isNull);
      expect(restored.dependsOnOperationId, isNull);
    });

    test('barcha kind va status qiymatlari aylanadi', () {
      for (final kind in PendingOperationKind.values) {
        for (final status in PendingOperationStatus.values) {
          final sample = PendingOperation(
            id: 'op',
            kind: kind,
            entityType: 'appeal',
            entityId: 'appeal-1',
            payload: const {},
            createdAt: DateTime.utc(2026),
            status: status,
          );

          final restored = PendingOperation.fromJson(sample.toJson());

          expect(restored.kind, kind);
          expect(restored.status, status);
        }
      }
    });

    test('faqat primitiv qiymatlar ishlatiladi (istalgan saqlashga mos)', () {
      final json = operation.toJson();

      for (final entry in json.entries) {
        final value = entry.value;
        expect(
          value == null || value is String || value is num || value is bool || value is Map,
          isTrue,
          reason: '${entry.key} primitiv bo\'lishi kerak, keldi: ${value.runtimeType}',
        );
      }
    });
  });

  group('buzilgan ma\'lumot', () {
    test('noma\'lum kind jimgina standartga tushmaydi', () {
      // Jimgina `createRecord`ga tushib qolish serverga MUTLAQO
      // boshqa so'rov yuborishga olib kelardi.
      final json = operation.toJson()..['kind'] = 'nomavjud_kind';

      expect(() => PendingOperation.fromJson(json), throwsFormatException);
    });

    test('noma\'lum status jimgina standartga tushmaydi', () {
      final json = operation.toJson()..['status'] = 'nomavjud_status';

      expect(() => PendingOperation.fromJson(json), throwsFormatException);
    });
  });

  group('resetForManualRetry', () {
    test('urinishlar tarixi tozalanadi va amal navbatga qaytadi', () {
      final blocked = operation.markNeedsAttention('doimiy xatolik');

      final reset = blocked.resetForManualRetry();

      expect(reset.status, PendingOperationStatus.pending);
      expect(reset.attemptCount, 0);
      expect(reset.lastAttemptAt, isNull);
      expect(reset.lastError, isNull);
    });

    test('identifikator va bog\'liqlik saqlanadi', () {
      final reset = operation.markNeedsAttention('xato').resetForManualRetry();

      expect(reset.id, 'op-1');
      expect(reset.dependsOnOperationId, 'op-parent');
      expect(reset.payload, operation.payload);
    });
  });

  group('takrorlanish qoidasi', () {
    PendingOperation sample(PendingOperationKind kind, {String entityId = 'appeal-1'}) {
      return PendingOperation(
        id: 'x',
        kind: kind,
        entityType: 'appeal',
        entityId: entityId,
        payload: const {},
        createdAt: DateTime.utc(2026),
      );
    }

    test('faqat updateRecord almashtirishga ruxsat beradi', () {
      for (final kind in PendingOperationKind.values) {
        expect(
          kind.supersedesPending,
          kind == PendingOperationKind.updateRecord,
          reason: '${kind.name} uchun noto\'g\'ri qoida',
        );
      }
    });

    test('boshqa yozuvning tahriri o\'rnini bosmaydi', () {
      final first = sample(PendingOperationKind.updateRecord);
      final other = sample(PendingOperationKind.updateRecord, entityId: 'appeal-2');

      expect(first.canBeSupersededBy(other), isFalse);
    });

    test('bir xil yozuvning tahriri o\'rnini bosadi', () {
      final first = sample(PendingOperationKind.updateRecord);
      final second = sample(PendingOperationKind.updateRecord);

      expect(first.canBeSupersededBy(second), isTrue);
    });
  });
}

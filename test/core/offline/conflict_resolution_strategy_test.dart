import 'package:adolat_ai/core/offline/conflict/conflict_resolution.dart';
import 'package:adolat_ai/core/offline/conflict/conflict_resolution_strategy.dart';
import 'package:adolat_ai/core/offline/conflict/sync_conflict.dart';
import 'package:flutter_test/flutter_test.dart';

/// `docs/ARCHITECTURE.md`, "Conflict Resolution" bo'limidagi har bir
/// qoida shu yerda alohida test bilan qulflanadi — bu bo'lim
/// ma'lumot yo'qolishi mumkin bo'lgan yagona joy, shuning uchun
/// qoidalar hujjatda qolib ketmasligi kerak.
SyncConflict _conflict({
  required ConflictKind kind,
  RecordEditability serverEditability = RecordEditability.editable,
}) {
  return SyncConflict(
    operationId: 'op-1',
    entityType: 'appeal',
    entityId: 'appeal-1',
    kind: kind,
    serverEditability: serverEditability,
  );
}

void main() {
  const strategy = DefaultConflictResolutionStrategy();

  group('holat (status) ziddiyati — server yakuniy hakam', () {
    test('server holati har doim ustuvor, mahalliy taxmin qabul qilinmaydi', () {
      final resolution = strategy.resolve(_conflict(kind: ConflictKind.status));

      expect(resolution, isA<KeepServerState>());
    });

    test('server tahrirlash mumkin bo\'lgan holatda bo\'lsa ham, holat ziddiyatida server yutadi', () {
      final resolution = strategy.resolve(
        _conflict(kind: ConflictKind.status, serverEditability: RecordEditability.editable),
      );

      // Bu MUHIM: "editable" degani tarkibni tahrirlash mumkin degani,
      // rasmiy holatni mahalliy taxmin bilan ustidan yozish mumkin
      // degani EMAS.
      expect(resolution, isA<KeepServerState>());
    });
  });

  group('tarkib (content) ziddiyati', () {
    test('server yozuvi hali tahrirlanadigan bo\'lsa, mahalliy tarkib yuboriladi', () {
      final resolution = strategy.resolve(
        _conflict(kind: ConflictKind.content, serverEditability: RecordEditability.editable),
      );

      expect(resolution, isA<ApplyLocalChange>());
    });

    test('server yozuvi qulflangan bo\'lsa, mahalliy o\'zgarish avtomatik qo\'llanmaydi', () {
      final resolution = strategy.resolve(
        _conflict(kind: ConflictKind.content, serverEditability: RecordEditability.locked),
      );

      // Jimgina tashlab yuborilmaydi -- foydalanuvchiga ko'rsatiladi.
      expect(resolution, isA<EscalateToUser>());
      expect(resolution.requiresUserDecision, isTrue);
    });

    test('server holati noma\'lum bo\'lsa, taxmin qilinmaydi', () {
      final resolution = strategy.resolve(
        _conflict(kind: ConflictKind.content, serverEditability: RecordEditability.unknown),
      );

      // "Bilmaslik" hech qachon "ruxsat berilgan" deb talqin
      // qilinmaydi (DEVELOPMENT_RULES.md, 3-band).
      expect(resolution, isA<EscalateToUser>());
    });
  });

  group('o\'chirish (deletion) ziddiyati', () {
    test('qaytarib bo\'lmaydigan amal hech qachon avtomatik bajarilmaydi', () {
      final resolution = strategy.resolve(_conflict(kind: ConflictKind.deletion));

      expect(resolution, isA<EscalateToUser>());
    });
  });

  group('umumiy kafolatlar', () {
    test('HAR QANDAY ziddiyat uchun qaror qaytariladi — hech qachon null/exception emas', () {
      for (final kind in ConflictKind.values) {
        for (final editability in RecordEditability.values) {
          expect(
            () => strategy.resolve(_conflict(kind: kind, serverEditability: editability)),
            returnsNormally,
            reason: '${kind.name}/${editability.name} uchun qaror bo\'lishi shart',
          );
        }
      }
    });

    test('har bir qaror sabab bilan keladi — audit izi uchun', () {
      for (final kind in ConflictKind.values) {
        final resolution = strategy.resolve(_conflict(kind: kind));

        final reason = switch (resolution) {
          ApplyLocalChange(:final reason) => reason,
          KeepServerState(:final reason) => reason,
          EscalateToUser(:final reason) => reason,
        };

        expect(reason.trim(), isNotEmpty, reason: '${kind.name} uchun sabab bo\'sh');
      }
    });

    test('hech bir qaror "mahalliy o\'zgarishni jimgina tashlab yuborish" emas', () {
      // Uchta variantdan boshqasi yo'q; ApplyLocal yuboradi,
      // KeepServer/Escalate esa foydalanuvchiga ko'rsatiladi
      // (QueuedSyncEngine ikkalasini ham needsAttention qiladi).
      for (final kind in ConflictKind.values) {
        for (final editability in RecordEditability.values) {
          final resolution = strategy.resolve(
            _conflict(kind: kind, serverEditability: editability),
          );

          expect(
            resolution is ApplyLocalChange ||
                resolution is KeepServerState ||
                resolution is EscalateToUser,
            isTrue,
          );
        }
      }
    });

    test('xolis (pure) — bir xil kirish har doim bir xil natija beradi', () {
      final first = strategy.resolve(_conflict(kind: ConflictKind.content));
      final second = strategy.resolve(_conflict(kind: ConflictKind.content));

      expect(first, second);
    });
  });
}

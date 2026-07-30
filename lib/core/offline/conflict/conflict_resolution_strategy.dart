import 'conflict_resolution.dart';
import 'sync_conflict.dart';

/// Ziddiyatni hal qilish strategiyasining ABSTRAKT shartnomasi.
///
/// Almashtiriladigan chegara: kelgusida biror feature o'ziga xos
/// qoidaga muhtoj bo'lsa (masalan fayl biriktirish uchun boshqacha),
/// `QueuedSyncEngine`ga boshqa implementatsiya berish yetarli.
abstract interface class ConflictResolutionStrategy {
  ConflictResolution resolve(SyncConflict conflict);
}

/// `docs/ARCHITECTURE.md`, "Conflict Resolution" bo'limidagi
/// qoidalarning TO'G'RIDAN-TO'G'RI, xolis (pure) ifodasi.
///
/// Qoidalar (hujjatdagi tartibda):
///
/// 1. **Server — yakuniy hakam (`ConflictKind.status`):** yozuv HOLATI
///    bo'yicha har doim server ustuvor — *"hech qachon serverdagi
///    rasmiy holat mahalliy taxmin bilan jimgina ustidan
///    yozilmaydi"*.
/// 2. **Tarkib — mahalliy ustuvor, LEKIN faqat ruxsat etilgan
///    holatda (`ConflictKind.content`):** server tomonda yozuv hali
///    `editable` bo'lsa, mahalliy versiya yuboriladi; `locked` bo'lsa
///    — mahalliy o'zgarish qabul QILINMAYDI va foydalanuvchiga
///    tushuntiriladi.
/// 3. **`unknown` — hech qachon taxmin qilinmaydi:** server holati
///    noma'lum bo'lsa, qaror foydalanuvchiga qoldiriladi. Bu ataylab
///    "ehtiyotkor" (conservative) tanlov — `DEVELOPMENT_RULES.md`,
///    3-band ("taxmin qilib kod yozilmaydi") ish vaqtidagi qarorga ham
///    tatbiq etilgan.
/// 4. **O'chirish (`ConflictKind.deletion`):** server tomonda yozuv
///    o'zgargan bo'lsa, o'chirish AVTOMATIK bajarilmaydi —
///    qaytarib bo'lmaydigan amal hech qachon taxminga asoslanmaydi.
///
/// **Bu strategiya hech qachon ma'lumotni jimgina yo'qotmaydi:**
/// uchala natijaning har biri yo mahalliy o'zgarishni yuboradi, yo
/// foydalanuvchiga aniq sabab bilan ko'rsatiladi
/// (`QueuedSyncEngine` `KeepServerState`ni ham `needsAttention`
/// holatiga aylantiradi).
class DefaultConflictResolutionStrategy implements ConflictResolutionStrategy {
  const DefaultConflictResolutionStrategy();

  @override
  ConflictResolution resolve(SyncConflict conflict) {
    return switch (conflict.kind) {
      ConflictKind.status => const KeepServerState(
        reason:
            'Yozuv holati server tomonda o\'zgargan — rasmiy holat '
            'mahalliy taxmindan ustun (server wins on state).',
      ),
      ConflictKind.content => _resolveContentConflict(conflict),
      ConflictKind.deletion => const EscalateToUser(
        reason:
            'Yozuv server tomonda o\'zgargan, mahalliy tomonda esa '
            'o\'chirish so\'ralgan — o\'chirish qaytarib bo\'lmaydigan '
            'amal, shuning uchun avtomatik bajarilmaydi.',
      ),
    };
  }

  ConflictResolution _resolveContentConflict(SyncConflict conflict) {
    return switch (conflict.serverEditability) {
      RecordEditability.editable => const ApplyLocalChange(
        reason:
            'Yozuv server tomonda hali tahrirlash mumkin bo\'lgan '
            'holatda — mahalliy tarkib yuboriladi.',
      ),
      RecordEditability.locked => const EscalateToUser(
        reason:
            'Yozuv server tomonda allaqachon rasmiylashgan (tahrirlab '
            'bo\'lmaydigan) holatga o\'tgan — mahalliy o\'zgarish '
            'avtomatik qo\'llanmaydi.',
      ),
      RecordEditability.unknown => const EscalateToUser(
        reason:
            'Server tomonidagi holat aniqlanmadi — noaniqlik '
            'foydalanuvchi ma\'lumoti hisobiga hal qilinmaydi.',
      ),
    };
  }
}

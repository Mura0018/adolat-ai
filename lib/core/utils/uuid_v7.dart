import 'dart:math';
import 'dart:typed_data';

/// **UUID v7 generatori** (RFC 9562) — `docs/adr/ADR-009-offline-identifier-strategy.md`
/// (Qabul qilingan 2026-07-31) qarorining amalga oshirilishi.
///
/// **Nega paket emas, o'z implementatsiyasi:** ADR-009 ikkala yo'lni
/// ham ruxsat etadi. Bu yerda o'z implementatsiyasi tanlandi, chunki
/// spetsifikatsiya kichik (128 bit, ikkita bayroq maydoni), Dart
/// yadrosining o'zi yetarli (`dart:math`, `dart:typed_data`), va
/// loyiha bo'ylab bog'liqliklarni minimal saqlash izchil intizom
/// bo'lib kelgan. Evaziga to'g'rilik testlar bilan qulflanadi
/// (`test/core/utils/uuid_v7_test.dart` — versiya/variant bitlari,
/// tartiblanish, noyoblik).
///
/// **Format (RFC 9562, 5.7-bo'lim):**
/// ```
///  0                   1                   2                   3
///  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                       unix_ts_ms (48 bit)                     |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |  ver (4) |          rand_a (12)  |var(2)|   rand_b (62)       |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// ```
///
/// **Nega v7, v4 emas** (ADR-009ning qisqa xulosasi): birinchi 48 bit
/// vaqt tamg'asi bo'lgani uchun yangi yozuvlar PostgreSQL B-tree
/// indeksining oxiriga ketma-ket tushadi — v4ning tasodifiy
/// taqsimoti esa indeks bo'ylab sochiladi. Loyiha 1 million
/// foydalanuvchi miqyosiga mo'ljallangan, va bu keyinchalik
/// o'zgartirish qiyin qaror.
abstract final class UuidV7 {
  /// Kriptografik tasodifiylik — **majburiy talab** (ADR-009,
  /// "Xavfsizlik ta'siri").
  ///
  /// Oddiy `Random()` ishlatilsa, identifikatorlar bashorat
  /// qilinadigan bo'lib qoladi. RLS himoyani saqlab qolsa ham
  /// (`author_id = auth.uid()`), bu keraksiz zaiflik bo'lardi.
  static final Random _secureRandom = Random.secure();

  /// Yangi UUID v7 qaytaradi (kanonik `8-4-4-4-12` shaklda).
  ///
  /// [now] va [random] faqat TEST uchun beriladi — ishlab chiqarish
  /// kodida hech qachon uzatilmaydi.
  static String generate({DateTime? now, Random? random}) {
    final milliseconds = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rng = random ?? _secureRandom;
    final bytes = Uint8List(16);

    // 0..5 -- 48 bitlik vaqt tamg'asi, katta-endian (big-endian).
    bytes[0] = (milliseconds >> 40) & 0xFF;
    bytes[1] = (milliseconds >> 32) & 0xFF;
    bytes[2] = (milliseconds >> 24) & 0xFF;
    bytes[3] = (milliseconds >> 16) & 0xFF;
    bytes[4] = (milliseconds >> 8) & 0xFF;
    bytes[5] = milliseconds & 0xFF;

    // 6..15 -- tasodifiy qism.
    for (var i = 6; i < 16; i++) {
      bytes[i] = rng.nextInt(256);
    }

    // Versiya (7) -- 6-baytning yuqori 4 biti.
    bytes[6] = (bytes[6] & 0x0F) | 0x70;

    // Variant (RFC 4122/9562, `10`) -- 8-baytning yuqori 2 biti.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return _format(bytes);
  }

  static String _format(Uint8List bytes) {
    final hex = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) hex.write('-');
      hex.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  /// Matn kanonik UUID shaklidami — sinov va tekshiruv uchun.
  static bool isValid(String value) => _pattern.hasMatch(value);

  static final RegExp _pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Identifikator ichiga yozilgan yaratilish vaqti.
  ///
  /// **Diagnostika uchun** — ishlab chiqarish mantig'i bunga
  /// tayanmasligi kerak: yozuvning haqiqiy vaqti `created_at`
  /// ustunida. ADR-009, "Xavfsizlik ta'siri": bu ma'lumot
  /// identifikatorning o'zida ochiq turadi.
  static DateTime? timestampOf(String uuid) {
    if (!isValid(uuid)) return null;
    final hex = uuid.replaceAll('-', '').substring(0, 12);
    // `isUtc: true` -- tamg'a absolyut (epoch) qiymat, shuning uchun
    // uni mahalliy vaqt mintaqasida talqin qilish noto'g'ri bo'lardi.
    return DateTime.fromMillisecondsSinceEpoch(int.parse(hex, radix: 16), isUtc: true);
  }
}

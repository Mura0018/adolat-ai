import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_local_database.g.dart';

/// Mahalliy (on-device) ma'lumotlar bazasining YAGONA jadvali —
/// `LocalStore` shartnomasining saqlash shakli (`docs/adr/ADR-007-offline-local-storage.md`,
/// Qabul qilingan 2026-07-31).
///
/// **Nega bitta umumiy jadval, har bir to'plam uchun alohida emas:**
/// `LocalStore<Map<String, Object?>>` shartnomasi kalit-qiymat
/// semantikasiga ega va to'plam nomlari ish vaqtida beriladi
/// (`LocalStorage.collection(name)`) — ya'ni ular kompilyatsiya
/// vaqtida ma'lum emas. Har bir to'plam uchun alohida jadval
/// yaratish har safar sxema migratsiyasini talab qilardi; bitta
/// jadval esa yangi to'plam qo'shilganda **migratsiyasiz** ishlaydi.
///
/// Kelgusida keshlangan ro'yxatlar (murojaat/nizo/qonunlar) uchun
/// TIPLANGAN jadvallar qo'shilishi mumkin — ular shu bazaga yangi
/// sxema versiyasi sifatida qo'shiladi va bu jadvalni almashtirmaydi.
@DataClassName('LocalStoreEntry')
class LocalStoreEntries extends Table {
  /// Avtomatik o'suvchi identifikator — **kiritilish tartibini**
  /// saqlaydi.
  ///
  /// Bu texnik tafsilot emas, **shartnoma talabi**: `LocalStore`
  /// hujjati `getAll()`/`keys()` uchun yozilish tartibini kafolatlaydi
  /// va `OfflineQueue`ning FIFO xatti-harakati aynan shunga tayanadi
  /// (`lib/core/offline/queue/offline_queue.dart`). SQL'da qatorlar
  /// tartibi kafolatlanmagani uchun tartib ANIQ ustunda saqlanadi.
  IntColumn get id => integer().autoIncrement()();

  /// To'plam nomi (`LocalStorage.collection(name)`).
  TextColumn get collection => text()();

  /// To'plam ichidagi kalit.
  TextColumn get key => text()();

  /// Qiymat — JSON matn ko'rinishida.
  ///
  /// `LocalStore` shartnomasi `Map<String, Object?>` bilan ishlaydi,
  /// ya'ni tuzilma oldindan ma'lum emas. JSON saqlash formatni
  /// moslashuvchan qoldiradi va `PendingOperation.toJson()` (Module
  /// 6C) bilan to'g'ridan-to'g'ri mos keladi.
  TextColumn get value => text()();

  /// Bitta to'plam ichida kalit takrorlanmaydi.
  @override
  List<Set<Column>> get uniqueKeys => [
    {collection, key},
  ];
}

/// Ilovaning mahalliy ma'lumotlar bazasi (Drift).
///
/// **Bu klass `lib/core/offline/` ICHIDA EMAS — ataylab.** Offline
/// yadrosi (navbat, dvigatel, ziddiyat qoidalari) hech qanday tashqi
/// paketga bog'lanmasligi shart va bu chegara
/// `test/core/offline/offline_architecture_boundary_test.dart` bilan
/// majburlanadi. Drift — INFRATUZILMA detali, shuning uchun u
/// `lib/services/` ichida, `dio_client`/`supabase` bilan bir qatorda
/// turadi. Yadro faqat `LocalStore` shartnomasini biladi.
@DriftDatabase(tables: [LocalStoreEntries])
class AppLocalDatabase extends _$AppLocalDatabase {
  AppLocalDatabase(super.e);

  /// Xotiradagi baza — testlar va vaqtinchalik ishlatish uchun.
  ///
  /// Doimiy emas, lekin `InMemoryLocalStore`dan FARQLI o'laroq
  /// haqiqiy SQL bajaradi — shuning uchun testlar sxema va
  /// so'rovlarning to'g'riligini ham tekshiradi.
  AppLocalDatabase.memory() : super(NativeDatabase.memory());

  /// Diskdagi baza — ilova ishga tushganda shu ishlatiladi.
  ///
  /// Fayl yo'lini CHAQIRUVCHI beradi (masalan `path_provider` orqali).
  /// Bu ataylab: yo'lni aniqlash platformaga bog'liq masala va u
  /// saqlash qatlamining vazifasi emas — shu bilan bu klass qo'shimcha
  /// paketga bog'lanmaydi.
  AppLocalDatabase.file(File file) : super(NativeDatabase(file));

  /// **Sxema versiyasi 1** (`ADR-007`, "Migration" mezoni).
  ///
  /// Har bir keyingi sxema o'zgarishi bu raqamni oshiradi VA
  /// [migration] ichiga mos qadam qo'shadi. Drift'ning migratsiya
  /// vositalari (sxema dumpi bilan taqqoslash) shu raqamga tayanadi.
  @override
  int get schemaVersion => 1;

  /// **Migratsiya strategiyasi.**
  ///
  /// `docs/ARCHITECTURE.md`, "Local Storage" → *"Doimiylik"*: mahalliy
  /// ma'lumot ilova yangilanishidan keyin ham saqlanib qolishi shart.
  /// Shu sababli bu yerda ma'lumotni O'CHIRIB, qaytadan yaratadigan
  /// "oson yo'l" ATAYLAB ishlatilmagan — u foydalanuvchining hali
  /// yuborilmagan murojaatini yo'qotardi.
  ///
  /// Kelgusi versiyalar uchun qoida: har bir `from`→`to` o'tish aniq
  /// yozilib, migratsiya testi bilan qoplanadi (ADR-007ning Drift
  /// tanlanishiga asosiy sabab shu edi).
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Hozircha yagona versiya (v1) mavjud, shuning uchun bu yerga
        // tushadigan holat yo'q. Kelgusida:
        //   if (from < 2) { await m.addColumn(...); }
        // ko'rinishida qadamma-qadam qo'shiladi.
      },
      beforeOpen: (OpeningDetails details) async {
        // Chet el kalitlari (foreign keys) SQLite'da standart holatda
        // o'chirilgan -- kelgusida tiplangan jadvallar qo'shilganda
        // yaxlitlik kafolati kerak bo'ladi.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

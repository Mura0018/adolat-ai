import 'package:adolat_ai/core/offline/storage/in_memory_local_store.dart';
import 'package:adolat_ai/core/offline/storage/local_store.dart';
import 'package:adolat_ai/services/local_database/app_local_database.dart';
import 'package:adolat_ai/services/local_database/drift_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// `LocalStore`/`LocalStorage` SHARTNOMASI — **ikkala implementatsiya
/// ustida bir xil bajariladi** (Module 7A).
///
/// **Nega bu eng muhim test:** offline yadrosining butun mantig'i
/// (navbat FIFO tartibi, bog'liqlik, hayot davri) `LocalStore`ning
/// xatti-harakatiga tayanadi. Agar Drift implementatsiyasi
/// `InMemoryLocalStore`dan bir joyda ham farq qilsa, doimiylik
/// yoqilgan kuni offline oqim **jimgina** buziladi — va buni birlik
/// (unit) testlari ushlay olmaydi, chunki ularning har biri o'z
/// implementatsiyasida to'g'ri ishlaydi.
///
/// Shu sababli bu yerda mock YO'Q: Drift haqiqiy SQLite (xotirada)
/// ustida ishlaydi, ya'ni sxema va so'rovlar ham tekshiriladi.
abstract class _Harness {
  Future<LocalStorage> create();
  Future<void> dispose();
}

class _InMemoryHarness implements _Harness {
  @override
  Future<LocalStorage> create() async => InMemoryLocalStorage();

  @override
  Future<void> dispose() async {}
}

class _DriftHarness implements _Harness {
  AppLocalDatabase? _db;

  @override
  Future<LocalStorage> create() async {
    final db = AppLocalDatabase.memory();
    _db = db;
    return DriftLocalStorage(db);
  }

  @override
  Future<void> dispose() async => _db?.close();
}

void main() {
  final harnesses = <String, _Harness Function()>{
    'InMemoryLocalStorage': _InMemoryHarness.new,
    'DriftLocalStorage': _DriftHarness.new,
  };

  harnesses.forEach((name, createHarness) {
    group('$name — LocalStore shartnomasi', () {
      late _Harness harness;
      late LocalStorage storage;
      late LocalStore<Map<String, Object?>> store;

      setUp(() async {
        harness = createHarness();
        storage = await harness.create();
        store = storage.collection('appeals');
      });

      tearDown(() async => harness.dispose());

      group('asosiy amallar', () {
        test('yozadi va o\'qiydi', () async {
          await store.put('a', {'title': 'Sinov'});

          expect(await store.get('a'), {'title': 'Sinov'});
        });

        test('mavjud bo\'lmagan kalit uchun null (xatolik emas)', () async {
          expect(await store.get('yo\'q'), isNull);
        });

        test('mavjud kalit ustiga yozadi', () async {
          await store.put('a', {'v': 1});
          await store.put('a', {'v': 2});

          expect(await store.get('a'), {'v': 2});
          expect(await store.count(), 1);
        });

        test('containsKey to\'g\'ri javob beradi', () async {
          await store.put('a', const {});

          expect(await store.containsKey('a'), isTrue);
          expect(await store.containsKey('b'), isFalse);
        });

        test('o\'chirish idempotent', () async {
          await expectLater(store.delete('yo\'q'), completes);
        });

        test('o\'chirilgan kalit qaytmaydi', () async {
          await store.put('a', const {});
          await store.delete('a');

          expect(await store.get('a'), isNull);
          expect(await store.count(), 0);
        });

        test('clear butun to\'plamni tozalaydi', () async {
          await store.put('a', const {});
          await store.put('b', const {});

          await store.clear();

          expect(await store.count(), 0);
          expect(await store.getAll(), isEmpty);
        });
      });

      group('tartib kafolati (FIFO ning asosi)', () {
        test('keys yozilish tartibini saqlaydi', () async {
          await store.put('birinchi', const {});
          await store.put('ikkinchi', const {});
          await store.put('uchinchi', const {});

          expect(await store.keys(), ['birinchi', 'ikkinchi', 'uchinchi']);
        });

        test('getAll yozilish tartibini saqlaydi', () async {
          await store.put('a', const {'n': 1});
          await store.put('b', const {'n': 2});

          expect(await store.getAll(), [
            {'n': 1},
            {'n': 2},
          ]);
        });

        test('mavjud kalit ustiga yozish tartibni O\'ZGARTIRMAYDI', () async {
          // Bu -- eng nozik parity nuqtasi: agar Drift ustiga
          // yozishda yangi qator qo'shsa (yoki id ni yangilasa),
          // qayta navbatga qo'yilgan amal navbat OXIRIGA sakrardi va
          // hech qachon yuborilmay qolishi mumkin edi.
          await store.put('a', const {'v': 1});
          await store.put('b', const {});
          await store.put('a', const {'v': 2});

          expect(await store.keys(), ['a', 'b']);
        });

        test('o\'chirib qayta yozilgan kalit OXIRIGA tushadi', () async {
          await store.put('a', const {});
          await store.put('b', const {});
          await store.delete('a');
          await store.put('a', const {});

          expect(await store.keys(), ['b', 'a']);
        });
      });

      group('qiymat turlari', () {
        test('ichma-ich (nested) tuzilma saqlanadi', () async {
          const value = {
            'text': 'matn',
            'count': 42,
            'flag': true,
            'nested': {'a': 1},
            'list': [1, 2, 3],
            'nothing': null,
          };

          await store.put('a', value);

          expect(await store.get('a'), value);
        });

        test('bo\'sh xarita saqlanadi', () async {
          await store.put('a', const {});

          expect(await store.get('a'), isEmpty);
        });

        test('maxsus belgilar va o\'zbek harflari buzilmaydi', () async {
          const value = {'text': "Bo'shatildi — «hujjat» \\ \" ' \n тест 😀"};

          await store.put('a', value);

          expect(await store.get('a'), value);
        });
      });

      group('nomlangan to\'plamlar', () {
        test('bir xil nom uchun ma\'lumot bir xil ko\'rinadi', () async {
          await storage.collection('appeals').put('a', const {'v': 1});

          expect(await storage.collection('appeals').get('a'), {'v': 1});
        });

        test('turli to\'plamlar mustaqil', () async {
          await storage.collection('appeals').put('a', const {'v': 1});
          await storage.collection('disputes').put('a', const {'v': 2});

          expect(await storage.collection('appeals').get('a'), {'v': 1});
          expect(await storage.collection('disputes').get('a'), {'v': 2});
        });

        test('bitta to\'plamni tozalash boshqasiga tegmaydi', () async {
          await storage.collection('appeals').put('a', const {});
          await storage.collection('disputes').put('b', const {});

          await storage.collection('appeals').clear();

          expect(await storage.collection('appeals').count(), 0);
          expect(await storage.collection('disputes').count(), 1);
        });

        test('clearAll barcha to\'plamlarni tozalaydi', () async {
          await storage.collection('appeals').put('a', const {});
          await storage.collection('disputes').put('b', const {});

          await storage.clearAll();

          expect(await storage.collection('appeals').count(), 0);
          expect(await storage.collection('disputes').count(), 0);
        });
      });
    });
  });
}

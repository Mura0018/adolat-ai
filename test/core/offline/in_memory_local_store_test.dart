import 'package:adolat_ai/core/offline/storage/in_memory_local_store.dart';
import 'package:adolat_ai/core/offline/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// `LocalStore`/`LocalStorage` SHARTNOMASINING testlari — doimiy
/// (Drift/Isar/Hive/sqflite — hali tanlanmagan) implementatsiya
/// kelganda xuddi shu xatti-harakat kutiladi.
void main() {
  group('LocalStore asosiy amallar', () {
    late LocalStore<Map<String, Object?>> store;

    setUp(() => store = InMemoryLocalStore<Map<String, Object?>>());

    test('yozadi va o\'qiydi', () async {
      await store.put('a', {'title': 'Sinov'});

      expect(await store.get('a'), {'title': 'Sinov'});
    });

    test('mavjud bo\'lmagan kalit uchun null qaytaradi (xatolik emas)', () async {
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

    test('o\'chirish idempotent — mavjud bo\'lmagan kalit xatolik bermaydi', () async {
      await expectLater(store.delete('yo\'q'), completes);
    });

    test('clear butun to\'plamni tozalaydi', () async {
      await store.put('a', const {});
      await store.put('b', const {});

      await store.clear();

      expect(await store.count(), 0);
      expect(await store.getAll(), isEmpty);
    });
  });

  group('tartib kafolati', () {
    test('getAll va keys yozilish tartibini saqlaydi', () async {
      // FIFO navbat shu kafolatga tayanadi -- shuning uchun bu
      // shartnomaning bir qismi, tasodifiy xatti-harakat emas.
      final store = InMemoryLocalStore<Map<String, Object?>>();
      await store.put('birinchi', const {});
      await store.put('ikkinchi', const {});
      await store.put('uchinchi', const {});

      expect(await store.keys(), ['birinchi', 'ikkinchi', 'uchinchi']);
    });

    test('mavjud kalit ustiga yozish tartibni o\'zgartirmaydi', () async {
      final store = InMemoryLocalStore<Map<String, Object?>>();
      await store.put('a', const {'v': 1});
      await store.put('b', const {});
      await store.put('a', const {'v': 2});

      expect(await store.keys(), ['a', 'b']);
    });
  });

  group('LocalStorage nomlangan to\'plamlari', () {
    test('bir xil nom uchun AYNAN bitta to\'plam qaytariladi', () async {
      final storage = InMemoryLocalStorage();

      await storage.collection('appeals').put('a', const {'v': 1});
      final sameCollection = storage.collection('appeals');

      // Aks holda ma'lumot "yo'qolgandek" ko'rinardi.
      expect(await sameCollection.get('a'), {'v': 1});
    });

    test('turli to\'plamlar bir-biridan mustaqil', () async {
      final storage = InMemoryLocalStorage();

      await storage.collection('appeals').put('a', const {'v': 1});
      await storage.collection('disputes').put('a', const {'v': 2});

      expect(await storage.collection('appeals').get('a'), {'v': 1});
      expect(await storage.collection('disputes').get('a'), {'v': 2});
    });

    test('clearAll barcha to\'plamlarni tozalaydi (masalan chiqishda)', () async {
      final storage = InMemoryLocalStorage();
      await storage.collection('appeals').put('a', const {});
      await storage.collection('disputes').put('b', const {});

      await storage.clearAll();

      expect(await storage.collection('appeals').count(), 0);
      expect(await storage.collection('disputes').count(), 0);
    });
  });

  group('cheklov ochiq hujjatlashtirilgan', () {
    test('yangi instance oldingi ma\'lumotni ko\'rmaydi (doimiylik YO\'Q)', () async {
      // Bu -- "Doimiylik (persistence)" talabining hali
      // QONDIRILMAGANINI qayd etuvchi test: in-memory implementatsiya
      // ataylab vaqtinchalik. Doimiy implementatsiya kelganda bu test
      // o'sha implementatsiya uchun TESKARISIGA yoziladi.
      final first = InMemoryLocalStore<Map<String, Object?>>();
      await first.put('a', const {'v': 1});

      final second = InMemoryLocalStore<Map<String, Object?>>();

      expect(await second.get('a'), isNull);
    });
  });
}

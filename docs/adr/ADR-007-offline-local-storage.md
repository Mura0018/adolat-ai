# ADR-007: Offline-First uchun doimiy Local Storage paketi

**Status:** Qabul qilingan (2026-07-31) — loyiha egasi tomonidan tasdiqlangan. Tanlangan variant: **Drift**. Amalga oshirish (paketni `pubspec.yaml`ga qo'shish va `LocalStore` implementatsiyasini yozish) hali **boshlanmagan** — u alohida vazifa sifatida rejalashtiriladi.

**Darajasi:** High (Module 6 yakuniy hisoboti — offline-first'ni bloklayotgan ikkita qarordan biri)

**Bog'liq hujjatlar:** `docs/ARCHITECTURE.md` ("Local Storage", "Offline-First Architecture", "Sync Engine"), `lib/core/offline/README.md`, `docs/SECURITY.md` ("JWT Security"), `docs/adr/ADR-001-data-residency.md`, `docs/adr/ADR-006-hybrid-infrastructure-strategy.md`

---

## Problem

Module 6 (Phase 6A–6C) offline-first qatlamining butun mantig'ini qurdi: navbat (FIFO + bog'liqlik + hayot davri), sinxronizatsiya dvigateli, qayta urinish, ziddiyat va tiklash. Barchasi `LocalStore<T>` shartnomasi ortida ishlaydi va `LocalStoreOfflineQueue` orqali saqlashga ulanadi.

Ammo **yagona mavjud implementatsiya — `InMemoryLocalStore`**, ya'ni ma'lumot ilova yopilganda yo'qoladi. Bu `docs/ARCHITECTURE.md`, "Local Storage" bo'limining **"Doimiylik (persistence)"** talabini — *"foydalanuvchi qurilmani o'chirib-yoqsa ham, hali sinxronlanmagan murojaat/nizo va navbatdagi vazifalar saqlanib qoladi"* — bajarmaydi.

Paket tanlanmaguncha offline-first **amalda ishlamaydi**: foydalanuvchi tarmoqsiz holatda murojaat yozadi, ilovani yopadi va ishi yo'qoladi — bu offline qatlamining asosiy va'dasiga to'g'ridan-to'g'ri zid.

Qaror `DEVELOPMENT_RULES.md`, 3-bandga muvofiq taxminga qoldirilmagan: saqlash paketi shifrlash, migratsiya va platforma qo'llab-quvvatlashi bo'yicha uzoq muddatli majburiyat yuklaydi.

## Nima uchun muhim

- **Ma'lumot yo'qolishi qaytarilmas:** navbatdagi amal — foydalanuvchining tarmoqsiz sharoitda yozgan huquqiy murojaati. Uni yo'qotish — mahsulotning asosiy vazifasini bajarmaslik (`docs/ROADMAP.md`, "Release Criteria": offline-first *"muzokara qilinmaydigan (non-negotiable) minimal talab"*).
- **Migratsiya — eng katta uzoq muddatli xavf:** mahalliy sxema ilova yangilanishlari bilan o'zgaradi. Migratsiya mexanizmi zaif bo'lsa, yangilanishdan keyin foydalanuvchining sinxronlanmagan ishi jimgina yo'qoladi — buni orqaga qaytarib bo'lmaydi va CI ushlamaydi.
- **Sinov imkoniyati loyihaning yagona sifat darvozasiga bog'liq:** `.github/workflows/ci.yml` faqat `flutter analyze` + `flutter test` ishga tushiradi, **emulator yoki qurilma yo'q**. Qurilmasiz sinab bo'lmaydigan paket 633 testli darvozadan tashqarida qoladi.
- **Sezgir ma'lumot qurilmada:** ADR-001 (data residency) hali Bloklangan; qurilmadagi nusxa uchun shifrlash imkoniyati qaror mezoni bo'lishi shart (`docs/SECURITY.md`).

## Ko'rib chiqilgan variantlar

### A. Drift (SQLite ustida tur-xavfsiz qatlam, kodgen bilan)

- **Afzalliklari:** haqiqiy SQL (indeks, join, tranzaksiya, filtrlash) — *"faqat ko'rish uchun offline qamrov"* talabidagi keshlangan ro'yxatlar uchun to'g'ridan-to'g'ri mos; kompilyatsiya vaqtida tekshiriladigan so'rovlar; **birinchi darajali migratsiya** (sxema versiyalari, qadamma-qadam `onUpgrade`, sxema dumplarini taqqoslovchi test vositalari); tranzaksiya kafolati navbat yaxlitligi uchun muhim.
- **Kamchiliklari:** kodgen (`build_runner`) — qo'shimcha qurish bosqichi; oddiy kalit-qiymat ehtiyoji uchun ortiqcha og'ir; o'rganish narxi boshqalardan yuqori.
- **Performance:** SQLite — sinovdan o'tgan; katta ro'yxatlarda indeks bilan eng yaxshi natija; alohida izolatda (isolate) ishlatish mumkin, UI bloklanmaydi. Sof kalit-qiymat o'qishda Hive'dan sekinroq (amaliy farq bu loyiha hajmida sezilmaydi).
- **Migration:** **eng kuchli variant** — versiyalangan sxema, migratsiya qadamlari va migratsiyani sinovdan o'tkazish vositalari mavjud.
- **Testability:** **xotiradagi ma'lumotlar bazasi** bilan oddiy `flutter test` ichida ishlaydi — mock talab qilinmaydi, haqiqiy SQL bajariladi; CI'da qurilma kerak emas.
- **Flutter qo'llab-quvvatlashi:** Android/iOS/macOS/Windows/Linux; web uchun WASM yo'li mavjud.
- **Uzoq muddatli maintenance:** faol va uzoq yillik tarixga ega; SQLite'ning o'zi esa o'nlab yillik barqarorlikka ega — paket to'xtasa ham ma'lumot formati o'qiladigan bo'lib qoladi.
- **Enterprise mosligi:** yuqori — migratsiya, tranzaksiya va shifrlash (SQLCipher yo'li) talablari qondiriladi.

### B. Isar (Dart uchun NoSQL, kodgen bilan)

- **Afzalliklari:** juda tez; qulay so'rov API'si va indekslar; kuzatuv oqimlari (watchers); SQL bilishni talab qilmaydi.
- **Kamchiliklari:** **maintenance noaniqligi** — asosiy ishlab chiquvchining faolligi davriy to'xtagan, keyingi katta versiya uzoq vaqt tayyor bo'lmagan va jamoa fork'lari paydo bo'lgan; migratsiya qo'lda; web qo'llab-quvvatlashi cheklangan.
- **Performance:** eng tez variantlardan biri — bu loyihada hal qiluvchi ustunlik emas (navbat hajmi kichik).
- **Migration:** **zaif** — versiyalangan migratsiya freymvorki yo'q, sxema o'zgarishini dasturchi o'zi boshqaradi. Yuqoridagi "ma'lumot yo'qolishi" xavfi aynan shu yerda.
- **Testability:** native kutubxonani talab qiladi; CI'da binar fayllarni yuklab olish/ta'minlash qo'shimcha ish — loyihaning yengil CI oqimiga ishqalanish qo'shadi.
- **Flutter qo'llab-quvvatlashi:** mobil/desktop yaxshi; web eksperimental.
- **Uzoq muddatli maintenance:** **asosiy xavf shu yerda** — 5–10 yillik gorizontda saqlanadigan huquqiy platforma uchun noaniqlik qabul qilib bo'lmaydigan darajada yuqori.
- **Enterprise mosligi:** o'rtacha — tezlik yuqori, lekin boshqaruv va uzoq muddatli kafolat yetishmaydi.

### C. Hive (sof Dart kalit-qiymat)

- **Afzalliklari:** eng sodda; native bog'liqliksiz (sof Dart) — CI'da hech qanday ishqalanish yo'q; tez; hozirgi `LocalStore` shartnomasiga (kalit-qiymat) shakl jihatidan eng yaqin.
- **Kamchiliklari:** **so'rov va indeks yo'q** — keshlangan ro'yxatlarni filtrlash uchun butun to'plamni xotiraga o'qish kerak; box'lar aro tranzaksiya yo'q; migratsiya butunlay qo'lda; katta ma'lumotlar va siqish (compaction) bilan bog'liq muammolar tarixi mavjud.
- **Performance:** kichik kalit-qiymat yuklamada juda yaxshi; ma'lumot o'sgan sari va filtrlash kerak bo'lganda yomonlashadi.
- **Migration:** **eng zaif** — versiya maydonini va migratsiya kodini to'liq dasturchi yozadi.
- **Testability:** yuqori — sof Dart, `flutter test`da to'siqsiz ishlaydi.
- **Flutter qo'llab-quvvatlashi:** barcha platformalar, web ham.
- **Uzoq muddatli maintenance:** **xavf yuqori** — asosiy versiya uzoq vaqt yangilanmagan, jamoa fork'i (Hive CE) paydo bo'lgan; rasmiy yo'nalish noaniq.
- **Enterprise mosligi:** past-o'rtacha — tranzaksiya va migratsiya kafolatlari yo'qligi huquqiy ma'lumot uchun jiddiy cheklov.

### D. sqflite (SQLite'ning yupqa plagini, xom SQL)

- **Afzalliklari:** juda barqaror va uzoq tarixga ega; kodgen umuman yo'q; SQLite'ning barcha imkoniyatlari (indeks, tranzaksiya) mavjud; eng kam "sehr".
- **Kamchiliklari:** xom SQL satrlari — **kompilyatsiya vaqtida tekshiruv yo'q**, xato faqat ish vaqtida chiqadi; qo'lda mapping (DTO ↔ jadval) ko'p qo'l mehnati va takrorlanish (`DEVELOPMENT_RULES.md`, 7-band, DRY bilan ishqalanish); web qo'llab-quvvatlashi to'liq emas.
- **Performance:** Drift bilan bir xil (ikkalasi ham SQLite).
- **Migration:** o'rtacha-kuchli — versiya raqami va `onUpgrade` mavjud, lekin migratsiya kodi qo'lda yoziladi va uni sinovdan o'tkazish vositalari yo'q.
- **Testability:** oddiy `flutter test`da ishlashi uchun qo'shimcha FFI paketi va sozlash talab qiladi — mumkin, lekin bir necha qadam qo'shiladi.
- **Flutter qo'llab-quvvatlashi:** mobil kuchli; desktop/test FFI orqali; web cheklangan.
- **Uzoq muddatli maintenance:** yuqori — uzoq yillik barqaror ta'minot.
- **Enterprise mosligi:** o'rtacha-yuqori — ishonchli, lekin tur xavfsizligi va migratsiya vositalarining yo'qligi katta jamoada xato narxini oshiradi.

## Afzallik va kamchiliklar (qisqa xulosa)

| Mezon (vazn) | Drift | Isar | Hive | sqflite |
|---|---|---|---|---|
| Migratsiya ishonchliligi **(eng yuqori vazn)** | Kuchli | Zaif | Eng zaif | O'rtacha |
| CI'da (qurilmasiz) sinash | Kuchli | Zaif | Eng kuchli | O'rtacha |
| So'rov/indeks (kesh ro'yxatlari) | Kuchli | Kuchli | Yo'q | Kuchli |
| Tranzaksiya (navbat yaxlitligi) | Bor | Qisman | Yo'q | Bor |
| Uzoq muddatli maintenance | Yuqori | **Xavfli** | **Xavfli** | Yuqori |
| Tur xavfsizligi | Kuchli | Kuchli | O'rtacha | **Yo'q** |
| Shifrlash yo'li | Bor (SQLCipher) | Cheklangan | Bor (AES) | Bor (SQLCipher) |
| Qo'shimcha qurish bosqichi | Kodgen | Kodgen | Kodgen (qisman) | Yo'q |

## Tavsiya etilgan qaror

**Drift tanlanadi.** Qaror uchta loyihaga xos omilga tayanadi:

1. **Migratsiya — asosiy xavf, Drift esa unga yagona jiddiy javob.** Mahalliy sxema albatta o'zgaradi; migratsiya qo'lda yozilganda xato **jimgina ma'lumot yo'qolishiga** olib keladi va uni CI ushlay olmaydi. Drift versiyalangan migratsiya va uni sinovdan o'tkazish vositalarini beradi — bu boshqa uchala variantda yo'q yoki zaif.
2. **Kodgen narxi bu loyihada nolga yaqin.** Kamchilik sifatida ko'rsatilgan `build_runner` **allaqachon** loyihada (freezed/json_serializable) va CI oqimida (`dart run build_runner build`) mavjud. Ya'ni Drift'ning eng katta kamchiligi aynan shu loyihada qo'shimcha xarajat yaratmaydi — bu Drift foydasiga hal qiluvchi vaziyat.
3. **CI moslik.** Xotiradagi ma'lumotlar bazasi bilan `flutter test` ichida haqiqiy SQL bajariladi — qurilma kerak emas, ya'ni saqlash qatlami loyihaning yagona sifat darvozasi ichida qoladi.

**Isar va Hive rad etiladi** — birinchi navbatda maintenance noaniqligi sababli. Huquqiy platforma 5–10 yil saqlanadi; asosiy ta'minoti to'xtagan yoki fork'ga bo'lingan saqlash qatlami — hujjatlashtirilgan, lekin qabul qilib bo'lmaydigan xavf. Ikkinchidan, ikkalasining ham migratsiya hikoyasi zaif.

**sqflite — munosib ikkinchi o'rin.** Agar loyiha egasi kodgenni printsipial ravishda istamasa, sqflite to'g'ri tanlov bo'ladi: bir xil SQLite yadrosi, bir xil barqarorlik. Yo'qotiladigani — tur xavfsizligi va migratsiyani sinash vositalari.

## Uzoq muddatli ta'sir

Saqlash paketi ilovaning eng uzoq yashaydigan qarorlaridan biri: undagi ma'lumot foydalanuvchi qurilmasida yillar davomida qoladi. SQLite tanlash (Drift yoki sqflite orqali) ma'lumot formatini **paketdan mustaqil** qiladi — paket almashsa ham fayl o'qiladigan bo'lib qolaveradi. Bu Isar/Hive'ning ichki (proprietar) formatida mavjud emas.

## Migratsiya ta'siri

- Hozirgi kodga o'zgarish: **bitta klass** — `LocalStore` interfeysining Drift asosidagi implementatsiyasi. `LocalStoreOfflineQueue`, dvigatel, rejalashtiruvchi va koordinator **umuman o'zgarmaydi** (Module 6C shu maqsadda qurilgan).
- Mavjud `InMemoryLocalStore` o'chirilmaydi — u testlar uchun qoladi.
- Yangi paketlar `pubspec.yaml`ga qo'shiladi (drift, drift_dev, sqlite3_flutter_libs) — bu ADR **tasdiqlangandan keyin**, alohida vazifada.

## Xavfsizlik ta'siri

- Autentifikatsiya tokenlari bu qatlamga **hech qachon** yozilmaydi — ular `Flutter Secure Storage`da qoladi (`docs/ARCHITECTURE.md`, "Local Storage" → maxfiy ma'lumotlar chegarasi). Bu qoida `test/core/offline/offline_architecture_boundary_test.dart` bilan avtomatik majburlangan va o'zgarmaydi.
- Qurilmadagi murojaat/nizo matni sezgir. Drift SQLCipher orqali to'liq bazani shifrlash yo'lini beradi — **shifrlash yoqilishi kerakmi** degan qaror ADR-001 (data residency) natijasiga bog'liq va alohida hal qilinadi.

## Huquqiy/muvofiqlik ta'siri

Qurilmadagi nusxa — shaxsiy ma'lumotning bir shakli. ADR-001 hali Bloklangan bo'lgani uchun bu ADR **saqlanadigan ma'lumot tarkibini kengaytirmaydi**: faqat allaqachon `docs/ARCHITECTURE.md`da ruxsat etilgan ma'lumot turlari saqlanadi. Shifrlash va saqlash muddati siyosati ADR-001 yopilgandan keyin qayta ko'rib chiqiladi.

## Xarajat ta'siri

To'g'ridan-to'g'ri pul xarajati yo'q (barcha variantlar ochiq kodli va bepul). Xarajat — muhandislik vaqti: Drift'da boshlang'ich sozlash sqflite'dan biroz uzunroq, lekin migratsiya va so'rovlarda qaytib keladi.

## Yakuniy tavsiya

**Drift.** Sabab bitta jumlada: *bu loyihada eng katta uzoq muddatli xavf — migratsiya vaqtidagi jimgina ma'lumot yo'qolishi, va Drift shu xavfga yagona to'liq javob beradi; uning yagona jiddiy kamchiligi (kodgen) esa aynan shu loyihada allaqachon to'langan.*

**Eslatma (halollik uchun):** paketlarning maintenance holati vaqt bilan o'zgaradi. Yuqoridagi Isar/Hive bo'yicha baholar ushbu ADR yozilgan paytdagi holatga asoslangan — amalga oshirishdan oldin pub.dev'dagi oxirgi reliz sanasi va faollik ko'rsatkichlari **qayta tekshirilishi** tavsiya etiladi. Agar holat sezilarli o'zgargan bo'lsa, bu ADR qayta ko'rib chiqilishi mumkin.

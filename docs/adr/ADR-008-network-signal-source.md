# ADR-008: Tarmoq holati signalining manbai

**Status:** Qabul qilingan (2026-07-31) — loyiha egasi tomonidan tasdiqlangan. Tanlangan variant: **`NetworkStateMonitor` abstraksiyasi + `connectivity_plus` (turtki) + so'rov natijalari (haqiqat manbai)**. Amalga oshirish hali **boshlanmagan** — u alohida vazifa sifatida rejalashtiriladi.

**Darajasi:** High (Module 6 yakuniy hisoboti — offline-first'ni bloklayotgan ikkita qarordan ikkinchisi)

**Bog'liq hujjatlar:** `docs/ARCHITECTURE.md` ("Network State Handling", "Sync Engine"), `lib/core/offline/README.md`, `docs/adr/ADR-006-hybrid-infrastructure-strategy.md`, `docs/adr/ADR-007-offline-local-storage.md`

---

## Problem

Module 6, Phase 6B `NetworkStateMonitor` shartnomasini va uning boshqariladigan (qo'lda o'rnatiladigan) implementatsiyasini qurdi. `SyncScheduler` tarmoq **tiklanishida** sinxronizatsiyani avtomatik ishga tushiradi, `QueuedSyncEngine` esa sikl o'rtasidagi uzilishga to'g'ri reaksiya qiladi.

Yetishmayotgan yagona narsa — **haqiqiy signal manbai**: hozircha holat faqat dasturiy tarzda o'zgartiriladi, ya'ni ilova qurilmaning tarmoq holatini **bilmaydi**.

Muhim nozik jihat: `docs/ARCHITECTURE.md`, "Network State Handling" oflayn holatni ikki xil vaziyatni **birlashtirgan** holda ta'riflaydi — *"qurilmaning tarmoqqa umuman ulanmagani"* **va** *"qurilma ulangan-u, ammo backend'ga yeta olmayotgani (masalan zaif signal, server vaqtincha ishlamasligi)"*. Bu ikkinchi holat qaror uchun hal qiluvchi, chunki **qurilma interfeysi holatini o'lchaydigan hech qanday paket unga javob bera olmaydi**.

## Nima uchun muhim

- **Noto'g'ri "onlayn" xulosasi zararliroq:** Wi-Fi'ga ulangan, lekin internetga chiqmaydigan qurilma (mehmonxona/aeroport portali, cheklangan tarmoq, server uzilishi) interfeys darajasida "ulangan" deb ko'rinadi. Ilova shunga ishonsa, sinxronizatsiyani qayta-qayta boshlaydi, har safar muvaffaqiyatsiz tugaydi va foydalanuvchiga "sinxronlanmoqda" deb ko'rsatib turadi — bu `DEVELOPMENT_RULES.md`, 17–19-bandlar ("No Dead End Rule") ruhiga zid noto'g'ri holat ko'rsatish.
- **Noto'g'ri "oflayn" xulosasi ham zararli:** tarmoq bor bo'lsa-yu, ilova yo'q deb hisoblasa, foydalanuvchining ishi keraksiz kutib qoladi.
- **Bu qaror `pubspec.yaml`ga tegadi** — Module 6 davomida ataylab qo'shilmagan yagona narsa yangi bog'liqlik edi (`DEVELOPMENT_RULES.md`, 3-band).

## Ko'rib chiqilgan variantlar

### A. `connectivity_plus` paketi

- **Ishonchlilik:** qurilmaning tarmoq **interfeysi** holatini (Wi-Fi/mobil/yo'q) ishonchli va tez xabar qiladi. Lekin **internetga yoki backend'ga yetishni O'LCHAMAYDI** — bu paketning hujjatlashtirilgan cheklovi, kamchilik emas. Ya'ni u savolning faqat yarmiga javob beradi.
- **Offline-first mosligi:** qisman. "Tarmoq yo'qoldi" signalini **tez** beradi (bu qimmatli: sinxronizatsiyani darhol to'xtatish mumkin) va "interfeys qaytdi" signalini beradi — bu `SyncScheduler` uchun yaxshi **turtki**, lekin haqiqat manbai emas.
- **Test qulayligi:** paketning o'zi platforma kanaliga tayanadi, shuning uchun to'g'ridan-to'g'ri test qilish qiyin. Lekin loyihada u `NetworkStateMonitor` ortida qoladi — testlar mavjud `InMemoryNetworkStateMonitor` bilan davom etadi, ya'ni **test qulayligi buzilmaydi**.
- **Platformalarga mosligi:** Android, iOS, macOS, Windows, Linux, web — keng qamrov.
- **Dependency xavfi:** o'rtacha. Keng qo'llaniladigan, jamoa tomonidan qo'llab-quvvatlanadigan paket oilasining bir qismi; lekin baribir tashqi bog'liqlik. Xavf `NetworkStateMonitor` chegarasi bilan **cheklangan**: paket almashtirilsa, bitta implementatsiya fayli o'zgaradi.

### B. Maxsus platform channel (o'z qo'limiz bilan)

- **Ishonchlilik:** nazariy jihatdan `connectivity_plus` bilan bir xil — chunki u ham xuddi shu OS API'lariga murojaat qiladi. Amalda **pastroq**: har bir platformaning chekka holatlarini (VPN, dual-SIM, Doze rejimi, iOS'ning ruxsat modeli) qayta kashf qilish kerak bo'ladi.
- **Offline-first mosligi:** A variantidan farq qilmaydi — u ham faqat interfeys holatini beradi.
- **Test qulayligi:** past — Android/iOS uchun native kod yoziladi, uni loyihaning `flutter test` darvozasi (emulatorsiz CI) **umuman qamrab olmaydi**.
- **Platformalarga mosligi:** har bir platforma uchun alohida ish; desktop/web qo'shimcha xarajat.
- **Dependency xavfi:** tashqi paket xavfi yo'q, lekin uning o'rniga **ichki maintenance qarzi** paydo bo'ladi: OS API'lari o'zgarganda tuzatish loyiha jamoasining ishiga aylanadi. Kichik jamoa uchun bu yomonroq savdo.

### C. Faqat "custom abstraction" (tashqi manbasiz)

- **Muhim aniqlik:** bu variant aslida A va B ga **alternativa emas** — `NetworkStateMonitor` abstraksiyasi allaqachon qurilgan va u yuqoridagi manbalardan **yuqori** turadigan qatlam. Savol "abstraksiya kerakmi" emas (u bor), balki "uni nima to'ldiradi" degan savol.
- **Manbasiz variant sifatida qaralganda:** yagona mumkin bo'lgan manba — **so'rov natijalari** (`SyncOperationOutcome`): amal `SyncTransientFailure` bilan tugasa, backend'ga yetib bo'lmayapti; muvaffaqiyatli tugasa, yetib bo'lyapti.
- **Ishonchlilik:** bu manba **haqiqatni** o'lchaydi (interfeysni emas) — ya'ni "ulangan, lekin yetib bo'lmaydi" holatini to'g'ri aniqlaydi. Kamchiligi: **passiv** — holat o'zgarganini faqat urinib ko'rgandan keyin biladi va tarmoq qaytganini o'zi sezmaydi (davriy urinishga tayanadi).
- **Test qulayligi:** eng yuqori — sof Dart, yangi bog'liqlik yo'q, hozirgi 190 ta offline testi bilan to'liq qamrab olinadi.
- **Platformalarga mosligi:** mutlaq (platformaga bog'liq kod yo'q).
- **Dependency xavfi:** nol.

## Afzallik va kamchiliklar (qisqa xulosa)

| Mezon | A: connectivity_plus | B: platform channel | C: faqat abstraksiya (so'rov natijasi) |
|---|---|---|---|
| Nimani o'lchaydi | Interfeys holati | Interfeys holati | **Backend'ga haqiqiy yetish** |
| "Ulangan, lekin yetib bo'lmaydi" | Aniqlamaydi | Aniqlamaydi | **Aniqlaydi** |
| Tarmoq qaytganini tez sezish | **Ha** | Ha | Yo'q (passiv) |
| Test qulayligi (CI, emulatorsiz) | O'rtacha (abstraksiya ortida — yaxshi) | Past | **Yuqori** |
| Platformalar | Keng | Har biri alohida ish | Mutlaq |
| Dependency xavfi | O'rtacha | Ichki maintenance qarzi | **Nol** |

## Tavsiya etilgan qaror

**Ikki manbali model qabul qilinadi:** `NetworkStateMonitor` (allaqachon mavjud abstraksiya) **arxitektura qarori bo'lib qoladi**, uning implementatsiyasi esa ikkita signalni birlashtiradi:

1. **`connectivity_plus` — TURTKI (hint), haqiqat emas.** Vazifasi ikkita: (a) interfeys yo'qolganda darhol `offline`ga o'tish (keraksiz urinishlarning oldini olish); (b) interfeys qaytganda `SyncScheduler`ga "endi urinib ko'rish mantiqiy" degan signal berish. Uning "ulangan" degan xabari **hech qachon "backend'ga yetib bo'ladi" deb talqin qilinmaydi**.
2. **So'rov natijalari — HAQIQAT manbai.** `SyncOperationOutcome.SyncTransientFailure` ketma-ket takrorlansa, holat `offline`ga o'tadi (interfeys "ulangan" desa ham); `SyncSuccess` kelishi bilan `online`ga qaytadi. Bu manba **hech qanday yangi bog'liqlik talab qilmaydi** — signal Module 6A'dan beri kodda mavjud.

**Platform channel (B) rad etiladi:** u `connectivity_plus` bilan bir xil ma'lumotni beradi, lekin uni olish narxi (per-platforma native kod, CI qamrovidan tashqarida qolishi, OS o'zgarishlarini kuzatish majburiyati) foydadan yuqori. Bu — mavjud va qo'llab-quvvatlanadigan yechimni qayta yozish.

**Faqat C (tashqi manbasiz) ham rad etiladi:** u to'g'ri, lekin passiv — tarmoq qaytganini o'zi sezmagani uchun foydalanuvchi ishi keraksiz kutib qolardi, bu esa *"internet qaytganda avtomatik sinxronizatsiya"* talabini zaiflashtiradi.

## Uzoq muddatli ta'sir

Qaror ADR-006dagi vendor mustaqilligi tamoyilini takrorlaydi: tashqi paket **almashtiriladigan detal**, arxitektura esa `NetworkStateMonitor` shartnomasida qoladi. `connectivity_plus` kelajakda to'xtasa yoki almashtirilsa, o'zgarish **bitta fayl** bilan cheklanadi va offline testlarining birortasi ham qayta yozilmaydi.

## Migratsiya ta'siri

- Hozirgi kodga o'zgarish: `NetworkStateMonitor` interfeysining yangi implementatsiyasi (bitta yangi fayl) + `SyncOperationHandler` natijalarini monitorga uzatuvchi yupqa bog'lanish.
- `SyncScheduler`, `SyncCoordinator`, `QueuedSyncEngine` va barcha testlar **o'zgarmaydi**.
- `InMemoryNetworkStateMonitor` saqlanadi — testlar uchun asosiy vosita bo'lib qoladi.
- `pubspec.yaml`ga bitta paket qo'shiladi — bu ADR **tasdiqlangandan keyin**, alohida vazifada.

## Xavfsizlik ta'siri

Tarmoq holati sezgir ma'lumot emas. Muhim cheklov: bu qatlam **hech qanday tarmoq so'rovi yubormaydi va hech qanday manzil (endpoint) bilmaydi** — "backend'ga yetish" haqidagi xulosa faqat `SyncOperationHandler` bergan natijadan olinadi. Shu bilan `test/core/offline/offline_architecture_boundary_test.dart` majburlaydigan chegara (offline qatlamida HTTP/manzil/kalit yo'q) **buzilmaydi**.

## Huquqiy/muvofiqlik ta'siri

Yo'q — tarmoq holati shaxsiy ma'lumot emas va hech qayerga uzatilmaydi. Paket qurilma tarmog'i haqida ma'lumotni tashqariga yubormaydi (faqat OS'dan o'qiydi); tanlangan paketning bu xossasi joriy etishdan oldin tasdiqlanishi kerak.

## Xarajat ta'siri

Pul xarajati yo'q. Muhandislik vaqti: A variantida kichik (bitta implementatsiya fayli), B variantida sezilarli darajada katta va davomiy.

## Yakuniy tavsiya

**`NetworkStateMonitor` abstraksiyasi + `connectivity_plus` (turtki sifatida) + so'rov natijalari (haqiqat manbai sifatida).**

Sabab bitta jumlada: *hujjat oflaynni "yetib bo'lmaydi" deb ta'riflaydi, interfeys holatini o'lchaydigan hech qanday paket esa bunga javob bera olmaydi — shuning uchun paket faqat tezkor turtki bo'lib qoladi, yakuniy hakam esa haqiqiy so'rov natijasi bo'ladi; bu ikkisini birlashtirish ikkalasining ham kamchiligini yopadi va yangi bog'liqlik xavfini bitta almashtiriladigan fayl bilan cheklaydi.*

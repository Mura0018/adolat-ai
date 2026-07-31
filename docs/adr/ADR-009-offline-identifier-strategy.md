# ADR-009: Offline yozuvlar uchun identifikator strategiyasi

**Status:** Qabul qilingan (2026-07-31) — loyiha egasi tomonidan tasdiqlangan. Tanlangan variant: **klient tomonda generatsiya qilinadigan UUID v7** (zaxira — v4). Amalga oshirish Module 7C doirasida boshlanadi.

**Darajasi:** High — **Module 7C ni bloklaydi** (offline qatlamini `appeals`/`disputes` bilan ulash)

**Bog'liq hujjatlar:** `docs/ARCHITECTURE.md` ("Offline-First Architecture", "Sync Engine" — idempotentlik), `docs/DATABASE.md`, `supabase/migrations/20260726000001_initial_schema_foundation.sql`, `docs/adr/ADR-007-offline-local-storage.md`, `docs/adr/ADR-008-network-signal-source.md`, `docs/adr/README.md` ("Navbatdagi ADR'lar" — shu masala 2026-07-28 dan beri ochiq deb qayd etilgan)

---

## Problem

Module 6 offline qatlamini, Module 7A–7B esa uning doimiy saqlash va tarmoq signalini qurdi. Qolgan yagona qadam — feature'larni shu qatlamga ulash (7C). Ammo ulashga urinishda hal qilinmagan savol yuzaga chiqdi:

**Foydalanuvchi tarmoqsiz murojaat yaratganda, yozuvning identifikatori qayerdan keladi?**

Hozirgi shartnoma buni oflaynda bajarib bo'lmaydigan qilib qo'ygan:

- `AppealsRepository.createDraft()` → `Future<Result<Appeal>>` — **server yaratgan** yozuvni qaytarishga va'da beradi;
- `Appeal` entity `id`, `authorId`, `createdAt`, `updatedAt`, `status` maydonlarini MAJBURIY talab qiladi;
- `AppealsRemoteDataSource.createDraft()` `.insert(...).select().single()` qiladi — ya'ni `id` ni **server** generatsiya qiladi.

Tarmoq bo'lmasa, qaytariladigan `Appeal` uchun `id` yo'q. Va bu shunchaki bitta maydon emas: identifikator allaqachon butun tizim bo'ylab tarqalgan —

| Qayerda | Nima uchun muhim |
|---|---|
| `attachments.appeal_id` (FK) | Oflaynda biriktirilgan fayl qaysi yozuvga bog'lanadi? |
| `case_status_history.appeal_id` (FK) | Audit izi qaysi yozuvga tegishli? |
| `/appeals/:appealId` (marshrut) | Foydalanuvchi ochgan ekran keyin ham amal qiladimi? |
| UI holati / Riverpod provayderlari | Yozuv id o'zgarsa, ekran nimaga ishora qiladi? |

**Tekshirilgan holat (2026-07-31):** loyihada lokal ↔ server id moslashtirish mexanizmi **umuman yo'q**; `SyncSuccess.remoteId` maydoni Module 6A'da e'lon qilingan, lekin uni **hech kim ishlatmaydi**.

## Nima uchun muhim

- **Offline-first `docs/ROADMAP.md`da "muzokara qilinmaydigan" talab.** Bu savolsiz Module 6–7 da qurilgan butun qatlam (≈2 400 qator + saqlash va tarmoq adapterlari) foydalanuvchiga hech qachon yetmaydi.
- **Xato qaytarib bo'lmaydigan:** identifikator strategiyasi ma'lumotlar bazasi darajasidagi qaror. Bir marta ishlab chiqarishga chiqqach, uni o'zgartirish mavjud yozuvlarni migratsiya qilishni talab qiladi — bu esa aynan foydalanuvchining huquqiy murojaatlari ustida bajariladigan xavfli amal.
- **Idempotentlik shunga tayanadi:** `docs/ARCHITECTURE.md`, "Sync Engine" — *"har bir navbatdagi amal mahalliy tomonda generatsiya qilingan barqaror identifikator bilan belgilanadi"*. Module 6 buni `PendingOperation.id` uchun bajardi, lekin YOZUVning o'zi uchun emas.

## Hozirgi holat — qarorga ta'sir qiluvchi dalillar

Bu ADR taxminga emas, sxemadan o'qilgan faktlarga tayanadi:

1. **Barcha jadvallarda id turi allaqachon UUID:**
   `id uuid primary key default gen_random_uuid()` — 10 ta jadvalda (`initial_schema_foundation.sql`).
2. **`default` faqat klient qiymat BERMAGANDA ishlaydi.** PostgreSQL klient bergan UUID'ni bemalol qabul qiladi — ya'ni klient tomonda id generatsiya qilish uchun **sxema migratsiyasi kerak emas**.
3. **RLS klient bergan id'ga to'sqinlik qilmaydi:**
   `create policy appeals_insert ... with check (author_id = auth.uid())` — siyosat FAQAT muallifni tekshiradi, `id`ni umuman cheklamaydi. Ya'ni **siyosat o'zgarishi ham kerak emas**.
4. **`created_at`/`updated_at`/`status` ham server standartiga ega** (`default now()`, `default 'draft'`) — ular ham klient bermasa server to'ldiradi.
5. **`uuid` paketi loyihada yo'q** — na to'g'ridan-to'g'ri, na tranzitiv bog'liqlik sifatida.

3-band ayniqsa muhim: u eng qimmat deb o'ylangan variantni (klient tomonda id) aslida **eng arzon** variantga aylantiradi.

## Ko'rib chiqilgan variantlar

### A. UUID v4 (klient tomonda, tasodifiy)

- **Offline-first mosligi:** to'liq — id yaratish uchun tarmoq kerak emas.
- **Sync murakkabligi:** eng past — id yaratilgan paytda YAKUNIY, hech qachon o'zgarmaydi, moslashtirish kerak emas.
- **Referential integrity:** to'liq — oflayn yaratilgan fayl darhol to'g'ri `appeal_id`ga bog'lanadi.
- **Performance:** o'rtacha — qiymatlar butunlay tasodifiy bo'lgani uchun B-tree indeksga yozish tarqoq (page split, WAL yozuvining kengayishi). Kichik hajmda sezilmaydi, million yozuvda sezilarli.
- **Collision:** amalda nol (122 bit tasodifiylik), **agar kriptografik tasodifiylik manbai ishlatilsa**.
- **PostgreSQL/Supabase:** mukammal — ustun turi allaqachon `uuid`, migratsiya kerak emas.
- **Flutter:** `uuid` paketi yoki ~20 qatorlik o'z implementatsiyasi (`Random.secure()` + RFC 9562 formatlash).
- **Maintenance:** eng yuqori — 20+ yillik standart, universal qo'llab-quvvatlash.
- **Enterprise:** yuqori. Faqat indeks lokalligi zaif nuqtasi.

### B. UUID v7 (klient tomonda, vaqt bo'yicha tartiblangan)

- **Offline-first mosligi:** A bilan bir xil — to'liq.
- **Sync murakkabligi:** A bilan bir xil — eng past.
- **Referential integrity:** A bilan bir xil — to'liq.
- **Performance:** **eng yaxshi.** Birinchi 48 bit — Unix millisekund vaqt tamg'asi, ya'ni yangi yozuvlar indeksning OXIRIGA ketma-ket tushadi. Bu B-tree page split'larini va WAL kengayishini keskin kamaytiradi — Zero-Regret Audit belgilagan 1 million foydalanuvchi miqyosida bu operatsion farq.
- **Collision:** amalda nol (74 bit tasodifiylik + vaqt prefiksi ayni millisekundgacha tor qiladi).
- **PostgreSQL/Supabase:** mukammal — bu ham oddiy `uuid` qiymati, ustun turi o'zgarmaydi. Server standarti (`gen_random_uuid()`, v4) zaxira sifatida qoladi; bitta ustunda v4 va v7 aralashishi texnik jihatdan muammosiz.
- **Flutter:** `uuid` paketi (4.x+ v7 ni qo'llab-quvvatlaydi) yoki o'z implementatsiyasi.
- **Maintenance:** yuqori — RFC 9562 (2024) bilan standartlashtirilgan; PostgreSQL 18 `uuidv7()` funksiyasini o'zi ham beradi.
- **Enterprise:** eng yuqori. **Yagona jiddiy e'tiroz:** id yaratilish VAQTINI ochib beradi (pastdagi "Xavfsizlik ta'siri" bo'limiga qarang).

### C. ULID

- **Offline-first mosligi:** to'liq.
- **Sync murakkabligi:** past.
- **Referential integrity:** to'liq.
- **Performance:** v7 ga o'xshash (vaqt bo'yicha tartiblangan).
- **Collision:** amalda nol (80 bit tasodifiylik).
- **PostgreSQL/Supabase:** **ishqalanish shu yerda.** ULID — 128 bit, ya'ni `uuid` ustuniga sig'adi, LEKIN uning yagona afzalligi — o'qishga qulay 26 belgili matn shakli — `uuid`ga aylantirilganda YO'QOLADI. Matn sifatida saqlash esa ustun turini o'zgartirishni (migratsiya) va kattaroq indeksni talab qiladi.
- **Flutter:** qo'shimcha paket; standart kutubxona qo'llab-quvvatlashi yo'q.
- **Maintenance:** o'rtacha — ommabop, lekin RFC standarti emas; ekotizim qo'llab-quvvatlashi UUID'dan ancha tor.
- **Enterprise:** o'rtacha. v7 bilan bir xil foyda, lekin ko'proq ishqalanish.

### D. Klient tomonda butun son (integer/snowflake)

- **Offline-first mosligi:** shartli — faqat har bir qurilmaga noyob "tugun identifikatori" (node id) berilsa ishlaydi.
- **Sync murakkabligi:** yuqori — node id taqsimlash mexanizmi kerak.
- **Referential integrity:** to'liq (agar to'qnashuv bo'lmasa).
- **Performance:** eng yaxshi (kichik, ketma-ket).
- **Collision:** **haqiqiy xavf** — node id noto'g'ri taqsimlansa yoki qurilma soati orqaga ketsa, ikki qurilma bir xil id yaratishi mumkin. Huquqiy yozuvlar ustida bu — bir foydalanuvchining murojaati ikkinchisinikini ustidan yozishi degani.
- **PostgreSQL/Supabase:** **10 ta jadvalda `uuid` → `bigint` migratsiyasi**, barcha FK'lar bilan birga. Eng qimmat variant.
- **Flutter:** o'z implementatsiyasi + node id boshqaruvi.
- **Maintenance:** past — o'z-o'zidan qurilgan mexanizmni yillar davomida qo'llab-quvvatlash kerak.
- **Enterprise:** **past** — foydasi yo'q, xarajati va xavfi eng yuqori.

### E. Server generatsiya qiladi (hozirgi holat)

- **Offline-first mosligi:** **yo'q** — bu aynan hozirgi bloker.
- **Sync murakkabligi:** o'rtacha (oflayn yaratish umuman qo'llab-quvvatlanmasa — past).
- **Referential integrity:** to'liq, lekin faqat onlayn.
- **Performance:** yaxshi.
- **Collision:** nol.
- **PostgreSQL/Supabase:** mukammal (hozir shunday ishlaydi).
- **Flutter:** hech narsa qilish kerak emas.
- **Maintenance:** yuqori.
- **Enterprise:** o'z-o'zicha yaxshi, LEKIN `docs/ROADMAP.md`ning "muzokara qilinmaydigan" offline-first talabini **bajarmaydi**. Uni saqlash — offline yaratishdan voz kechish demak.

### F. Gibrid (vaqtinchalik lokal id + server moslashtirish)

- **Offline-first mosligi:** to'liq.
- **Sync murakkabligi:** **eng yuqori.** Kerak bo'ladi: moslashtirish jadvali, sinxronizatsiyadan keyin FK'larni qayta yozish (`attachments.appeal_id`), id o'zgarganda UI holati va marshrutlarni yangilash, hali moslashtirilmagan id'ga ishora qiluvchi amallarni kutish.
- **Referential integrity:** **vaqtincha buziladi** — sinxronizatsiyagacha FK'lar mavjud bo'lmagan yozuvga ishora qiladi. Bu butun bir xatolar sinfini ochadi (osilib qolgan vaqtinchalik id, moslashtirish va navigatsiya o'rtasidagi poyga).
- **Performance:** yaxshi.
- **Collision:** past (lokal id faqat qurilma ichida noyob bo'lsa yetarli).
- **PostgreSQL/Supabase:** qo'shimcha jadval va yangilash mantig'i.
- **Flutter:** eng ko'p kod.
- **Maintenance:** past — murakkablik doimiy qarzga aylanadi.
- **Enterprise:** **faqat majburiyat bo'lganda.** Bu variant `bigserial` id ishlatadigan tizimlar uchun MAJBURIY yechim. Bu loyihada esa ustun allaqachon `uuid` — ya'ni gibridning butun murakkabligi **hech qanday foyda bermasdan** qo'shiladi.

## Qisqa taqqoslash

| Mezon | A: v4 | **B: v7** | C: ULID | D: integer | E: server | F: gibrid |
|---|---|---|---|---|---|---|
| Offline-first | ✅ | ✅ | ✅ | ⚠️ | ❌ | ✅ |
| Sync murakkabligi | Past | **Past** | Past | Yuqori | — | **Eng yuqori** |
| Referential integrity | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ vaqtincha buziladi |
| Performance (indeks) | O'rtacha | **Eng yaxshi** | Yaxshi | Eng yaxshi | Yaxshi | Yaxshi |
| Collision | ~0 | ~0 | ~0 | **Xavf bor** | 0 | Past |
| PostgreSQL/Supabase | Migratsiyasiz | **Migratsiyasiz** | Ishqalanish | **Katta migratsiya** | Hozirgi | Qo'shimcha jadval |
| Flutter narxi | Past | Past | O'rtacha | Yuqori | Nol | Yuqori |
| Maintenance | Yuqori | **Yuqori** | O'rtacha | Past | Yuqori | Past |

## Tavsiya etilgan qaror

**Klient tomonda generatsiya qilinadigan UUID v7.**

Uchta sabab, muhimlik tartibida:

**1. Repository shartnomasi O'ZGARMAYDI — bloker shu bilan yo'qoladi.**
Klient id'ni oldindan bilgani uchun `createDraft()` oflaynda ham to'liq shakllangan `Appeal` qaytara oladi. Ya'ni `AppealsRepository`ning imzosi, `Result<T>` konventsiyasi va domain qatlami **tegilmaydi**. Bu ADR-009ning eng qimmatli natijasi: 7C endi mavjud interfeyslarni buzmasdan bajarilishi mumkin.

**2. Sxema va RLS o'zgarishsiz qoladi.**
Yuqoridagi 1–3-dalillarga ko'ra ustun turi allaqachon `uuid`, `default` faqat klient jim qolganda ishlaydi, RLS esa `id`ni cheklamaydi. **Nol migratsiya, nol siyosat o'zgarishi** — ishlab chiqarishdagi ma'lumot ustida hech qanday xavfli amal bajarilmaydi.

**3. v4 o'rniga v7 — miqyoslash uchun.**
Ikkalasi ham funksional jihatdan bir xil (yakuniy, moslashtirishsiz id). Farq — indeks lokalligi: v4 tasodifiy bo'lgani uchun yozuvlar B-tree bo'ylab tarqaladi, v7 esa vaqt prefiksi tufayli ketma-ket tushadi. Loyiha aniq 1 million foydalanuvchi miqyosiga mo'ljallangan (`Zero-Regret Audit`), va bu tanlov keyinchalik o'zgartirish qiyin bo'lgan qaror — shuning uchun uni **hozir** to'g'ri qilish arzonroq. Qo'shimcha foyda: v7 vaqt bo'yicha tartiblangani uchun keyset-pagination'ni tabiiy qo'llab-quvvatlaydi — bu `docs/ACTION_PLAN.md`da ochiq turgan "pagination yo'q" topilmasiga to'g'ridan-to'g'ri yordam beradi.

**Rad etilganlar qisqacha:** D (integer) — 10 jadvallik migratsiya va to'qnashuv xavfi, foydasi yo'q. E (server) — offline talabini bajarmaydi, bloker shu. C (ULID) — v7 bilan bir xil foyda, ko'proq ishqalanish. F (gibrid) — texnik jihatdan ishlaydi, lekin butun murakkabligi ustun `uuid` bo'lgani uchun **keraksiz**; u `bigserial` tizimlar uchun majburiy yechim, bu yerda esa o'z-o'zidan yaratilgan muammo bo'lardi.

**Zaxira variant:** agar amalga oshirish paytida ishonchli v7 generatori topilmasa, **v4 qabul qilinadi**. Farq faqat unumdorlikda, to'g'rilikda emas — bu ADR'ning asosiy qarori (klient tomonda yakuniy UUID) o'zgarishsiz qoladi.

## Uzoq muddatli ta'sir

Identifikator turi — ma'lumotlar bazasining eng uzoq yashaydigan qarori. UUID tanlash ma'lumotni **joylashuvdan mustaqil** qiladi: yozuv qaysi qurilmada yaratilganidan qat'i nazar id yakuniy bo'ladi, ya'ni kelgusida ma'lumotni ko'chirish, birlashtirish yoki boshqa mintaqaga o'tkazish (ADR-001 natijasiga qarab kerak bo'lishi mumkin) hech qanday id qayta yozishni talab qilmaydi.

## Migratsiya ta'siri

- **Ma'lumotlar bazasi:** o'zgarish **yo'q**. Sxema ham, RLS ham tegilmaydi. Server standarti (`gen_random_uuid()`) zaxira sifatida qoladi — server tomonda yaratiladigan yozuvlar (masalan admin amallari) ishlashda davom etadi.
- **Mavjud yozuvlar:** tegilmaydi — ular allaqachon UUID.
- **Flutter:** id generatsiya qiluvchi kichik komponent (`uuid` paketi yoki o'z implementatsiyasi) va uni `createDraft` oqimiga ulash. `AppealsRepository`/`Appeal`/`Result` — o'zgarmaydi.
- **Qoladigan kichik masala:** `createdAt`/`updatedAt` ham server standartiga ega. Oflaynda ular klient tomonda taxminiy to'ldiriladi va sinxronizatsiyadan keyin server qiymati bilan yangilanadi. Bu ADR **identifikatorni** hal qiladi, vaqt tamg'alarini emas — ular id'dan farqli o'laroq o'zgarishi xavfsiz, chunki ularga hech qanday FK yoki marshrut tayanmaydi.

## Xavfsizlik ta'siri

- **v7 yaratilish vaqtini ochib beradi** — id ichidagi 48 bit millisekund tamg'asi. Ya'ni id'ni ko'rgan kishi yozuv qachon yaratilganini biladi.
  **Baho: past xavf.** Id'lar ommaviy emas — ularga kirish RLS bilan cheklangan (`author_id = auth.uid()`), va yozuv egasi `created_at`ni allaqachon ko'radi. Lekin bu ADR-001 (data residency) yopilganda qayta ko'rib chiqilishi kerak: agar id'lar tashqi tizimlarga (masalan davlat organi integratsiyasi) uzatilsa, metama'lumot chiqib ketishi qayta baholanadi.
- **Tasodifiylik manbai kritik:** id generatsiyasi **kriptografik** tasodifiylikka tayanishi shart (`Random.secure()`, oddiy `Random()` EMAS). Aks holda id'lar bashorat qilinadigan bo'lib qoladi — RLS himoyani saqlab qolsa ham, bu keraksiz zaiflik. Bu talab amalga oshirishda test bilan qulflanishi kerak.
- Klient bergan id RLS'ni **zaiflashtirmaydi**: siyosat `author_id`ni tekshiradi, `id`ni emas. Boshqa foydalanuvchining id'sini "taxmin qilish" hech narsa bermaydi.

## Huquqiy/muvofiqlik ta'siri

To'g'ridan-to'g'ri ta'sir yo'q. Bilvosita: v7 vaqt tamg'asi — bu shaxsiy ma'lumot emas, lekin foydalanuvchi faoliyati haqidagi metama'lumot. ADR-001 natijasi shaxsiy ma'lumot chegarasini qat'iylashtirsa, yuqoridagi "Xavfsizlik ta'siri" bandi qayta ko'rib chiqiladi.

## Xarajat ta'siri

Pul xarajati yo'q. Muhandislik vaqti: **eng arzon variantlardan biri** — migratsiya yo'q, shartnoma o'zgarishi yo'q. Taqqoslash uchun: F (gibrid) varianti moslashtirish jadvali, FK qayta yozish va UI holatini yangilash tufayli bir necha barobar qimmat bo'lardi.

## Yakuniy tavsiya

**Klient tomonda generatsiya qilinadigan UUID v7** (zaxira — v4).

Sabab bitta jumlada: *ma'lumotlar bazasi allaqachon `uuid` ustunini va klient bergan qiymatni qabul qiladi, RLS esa `id`ni cheklamaydi — shuning uchun eng murakkab ko'ringan muammo (lokal ↔ server id moslashtirish) aslida umuman mavjud emas: klient id'ni oldindan yaratsa, id birinchi kunidanoq yakuniy bo'ladi, referensial yaxlitlik hech qachon buzilmaydi va `AppealsRepository` shartnomasi tegilmasdan qoladi.*

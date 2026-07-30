# ACTION_PLAN.md — Adolat AI audit topilmalari harakat rejasi

Bu hujjat qayta ishlatiladigan shablon (pastdagi "Empty template for future actions" bo'limi) VA loyihaning haqiqiy audit topilmalari jurnalini ("Qayd etilgan topilmalar" bo'limi) birgalikda saqlaydi.

## Purpose

- Har bir audit (Security, Performance, UX) natijasida aniqlangan kamchiliklarni yagona, markazlashgan joyda kuzatish uchun (`docs/DEVELOPMENT_RULES.md`, 25-band: "Har bir audit kamchiligi ACTION_PLAN.md ga yoziladi va yopilgandan keyingina Sprint yakunlanadi").
- Maqsad — hech bir aniqlangan kamchilik og'zaki yoki tarqoq holda qolib ketmasligi, balki har biri yopilguncha kuzatilishi mumkin bo'lgan yozuvga aylanishi.
- Bu hujjat `docs/SECURITY.md`dagi "Security Checklist" va `docs/ROADMAP.md`dagi "Release Criteria" bilan bevosita bog'liq — u yerlarda talab qilingan "barcha topilmalar yopilgan" holati aynan shu hujjat orqali tasdiqlanadi.
- Critical darajadagi topilma yopilmaguncha Release chiqarilmaydi (`docs/DEVELOPMENT_RULES.md`, 24-band) — shuning uchun bu hujjatdagi yozuvlar reliz qarorining bevosita asosi hisoblanadi.

## Rules for recording audit findings

- Har bir audit (Security Audit, Performance Audit, UX Audit) yakunlangach, undagi barcha topilmalar — darajasidan qat'i nazar — darhol shu hujjatga yozuv sifatida kiritiladi (`docs/DEVELOPMENT_RULES.md`, 22-band).
- Har bir yozuv o'zi bilan ishlaydigan kishi uchun yetarli bo'lishi kerak: topilma nima, qayerda (qaysi modul/hujjat/funksiya) aniqlangan, qaysi audit va sanada topilgan.
- Yozuv **hech qachon o'chirilmaydi** — faqat holati (status) yangilanadi; yopilgan topilma ham keyingi audit tarixi va o'rganilgan saboq sifatida saqlanib qoladi.
- Sprint/Bosqich faqat tegishli davrda ochilgan barcha **Critical** va **High** darajadagi topilmalar "Bajarildi (Done)" holatiga o'tgandan keyingina yakunlanishi mumkin (`docs/DEVELOPMENT_RULES.md`, 23–25-bandlar; `docs/ROADMAP.md`, "Release Criteria" bo'limi).
- Har bir yozuvga aniq bitta **Owner** (mas'ul shaxs) tayinlanadi — bir nechta kishi "birgalikda mas'ul" bo'lgan holatga yo'l qo'yilmaydi, bu hisobdorlikni xiralashtiradi.
- Topilma bartaraf etilgach, yozilishi shart bo'lgan minimal ma'lumot: nima o'zgartirildi va bu o'zgarish topilmani qanday yopganini tasdiqlovchi qisqa izoh.

## Priority (Critical/High/Medium/Low)

- **Critical:** darhol e'tibor talab qiladi; hal qilinmaguncha Release chiqarilmaydi (`docs/DEVELOPMENT_RULES.md`, 24-band). Odatda xavfsizlik yoki ma'lumot yaxlitligiga bevosita xavf soladigan topilmalar shu darajaga kiradi.
- **High:** joriy Sprint/Bosqich yakunlanishidan oldin hal qilinishi shart; Release'ni bloklamasligi mumkin, lekin keyingi bosqichga o'tishni bloklaydi.
- **Medium:** yaqin orada hal qilinishi kerak, lekin joriy Sprint/Bosqichni bloklamaydi; navbatdagi Sprint/Bosqichga rejalashtiriladi.
- **Low:** kichik, shoshilinch bo'lmagan yaxshilanish; resurs bo'sh bo'lganda hal qilinadi.

## Status (Open/In Progress/Done)

- **Open:** topilma qayd etilgan, lekin ishlov hali boshlanmagan.
- **In Progress:** topilma ustida faol ishlanmoqda, mas'ul shaxs tayinlangan.
- **Done:** topilma bartaraf etilgan va tasdiqlangan (masalan qayta tekshiruv yoki keyingi audit orqali) — faqat shu holatdagi yozuvlar "yopilgan" deb hisoblanadi (`docs/DEVELOPMENT_RULES.md`, 25-band talabiga muvofiq).

## Owner

- Har bir yozuvda topilmani bartaraf etishga mas'ul **aniq bitta shaxs** ko'rsatiladi.
- Owner topilma "In Progress" holatiga o'tgan paytdan boshlab tayinlangan bo'lishi shart — "Open" holatida Owner hali belgilanmagan bo'lishi mumkin, lekin ishlov boshlanishidan oldin albatta tayinlanadi.
- Owner o'zgarganda (masalan boshqa kishiga topshirilganda), bu o'zgarish yozuv tarixida (Izohlar qismida) qayd etiladi — jimgina almashtirilmaydi.

## Target Sprint/Phase

- Har bir yozuv qaysi Sprint yoki `docs/ROADMAP.md`dagi Bosqich/Phase doirasida hal qilinishi rejalashtirilganini ko'rsatadi (masalan "Bosqich 1", "Bosqich 2").
- Critical darajadagi topilmalar uchun Target Sprint/Phase har doim **joriy** Sprint/Bosqich bo'lishi kerak — keyingi bosqichga surib qo'yilmaydi.
- Agar Target Sprint/Phase o'zgarsa (masalan kechiktirilsa), bu o'zgarish va uning sababi Izohlar qismida qayd etiladi.

## Qayd etilgan topilmalar (Recorded Findings)

Quyidagi jadvallar loyiha tarixida hozirgacha o'tkazilgan barcha audit va tekshiruvlarning topilmalarini qayd etadi (`DEVELOPMENT_RULES.md`, 22 va 25-bandlar bo'yicha talab qilingan, lekin shu paytgacha bu hujjatga yozilmagan holda qolgan — ushbu bo'lim shu bo'shliqni orqaga qarab (retroactively) yopadi). Katta hajm sababli, har bir topilma yuqoridagi to'liq shablon o'rniga qisqartirilgan jadval qatori sifatida yozilgan — barcha talab qilingan maydonlar (topilma, joy, ustuvorlik, holat, owner, sana, yechim) baribir mavjud. Yangi, alohida topilma qo'shishda yuqoridagi to'liq shablondan foydalanish davom etadi.

### 1. Schema Foundation migratsiyasi auditi — 2026-07-26

**Manba:** Senior-architect review, `supabase/migrations/20260726000001_initial_schema_foundation.sql`

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| RLS ba'zi jadvallarda yoqilmagan edi | Critical | Done | Claude Code | 2026-07-26 | 2026-07-26 | Barcha 13 jadvalda `enable row level security` qo'shildi, shu migratsiya ichida. |
| FK ustunlarida indeks yo'q edi (`category_id`, `recipient_body_id` va h.k.) | High | Done | Claude Code | 2026-07-26 | 2026-07-26 | 6 ta indeks qo'shildi (appeals/disputes/case_status_history/notifications). |
| Ba'zi FK'larda `ON DELETE` xatti-harakati aniq belgilanmagan edi | High | Done | Claude Code | 2026-07-26 | 2026-07-26 | `case_status_history`/`ai_analyses`/`attachments`/`notifications`ning `appeal_id`/`dispute_id` FK'lariga `on delete cascade` qo'shildi. |

### 2. RLS Policies migratsiyasi xavfsizlik auditi — 2026-07-26

**Manba:** Senior security audit, `supabase/migrations/20260726000002_rls_policies.sql`

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| `disputes_update_respondent` siyosati respondentga `status` ustunini o'zgartirishga yo'l qo'yib qo'yardi | High | Done | Claude Code | 2026-07-26 | 2026-07-26 | Siyosat qayta yozildi — respondent faqat `respondent_statement`ni o'zgartira oladi, "unchanged column" guard qo'shildi. Qayta audit orqali tasdiqlandi. |

### 3. Storage Foundation migratsiyasi xavfsizlik auditi — 2026-07-27

**Manba:** Senior security audit, `supabase/migrations/20260726000003_storage_foundation.sql`

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| Storage yo'lidagi UUID segmentini `::uuid`ga cast qilishdan oldin format tekshirilmagan edi (xato holatida noaniq xatolik xavfi) | High | Done | Claude Code | 2026-07-27 | 2026-07-27 | UUID regex guard (`^[0-9a-fA-F]{8}-...$`) cast'dan oldin qo'shildi, barcha 3 storage siyosatida. |

### 4. Authentication Foundation migratsiyasi xavfsizlik auditi — 2026-07-27

**Manba:** Senior security audit, `supabase/migrations/20260727000001_authentication_foundation.sql`

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| `handle_new_user()` funksiyasida aniq `search_path` xavfsizlik sozlamasi so'ralgan edi | — | Done | Claude Code | 2026-07-27 | 2026-07-27 | Tekshiruvda funksiya allaqachon `set search_path = ''` bilan to'g'ri yozilgani aniqlandi — o'zgarish kiritilmadi (kosmetik/keraksiz tahrirdan qochildi). |

### 5. Case Management Foundation audit + Pre-Phase 6 Hardening Sprint — 2026-07-28

**Manba:** Full Critical/High/Medium/Low audit (Flutter kod, RLS), so'ngra maxsus mustahkamlash sprinti

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| `appeals_update` RLS siyosati muallifga o'z murojaatini `draft` -> `submitted`ga o'tkazishga yo'l qo'ymas edi (ARCHITECTURE.md'dagi hujjatlashtirilgan niyatga zid) | Critical | Done | Claude Code | 2026-07-28 | 2026-07-28 | Xavfsizlik ta'siri tahlili yozildi, siyosat tuzatildi (keyinchalik authorization-hardening migratsiyasiga birlashtirildi, commit `568271b`). |
| Xom exception/failure matni foydalanuvchiga to'g'ridan-to'g'ri ko'rsatilardi (6 ta ekranda, 12 ta joyda) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Barcha joylar `describeErrorForUser()`/`.userMessage` orqali xavfsiz Uzbek xabarlarga almashtirildi. |
| Egalik/avtorizatsiya tekshiruvi 26+ joyda inline subquery sifatida takrorlangan edi (yagona haqiqat manbai yo'q) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | `is_admin()`/`owns_appeal()`/`is_dispute_party()`/`can_access_case()` funksiyalari yaratildi, commit `568271b`. |
| Hujjatlar (DATABASE.md, ROADMAP.md) haqiqiy qurilgan kod bilan sinxron emas edi | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Ikkala hujjat yangilandi, commit `b4f3024`. |
| Flutter kodi hech qachon haqiqiy kompilyator bilan tekshirilmagan edi (faqat qo'lda statik tahlil) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Flutter 3.44.8 o'rnatildi, `flutter analyze` ishga tushirildi: 67 topilma (7 ta haqiqiy xato) -> 0 xato, 4 ta ataylab qoldirilgan info-darajadagi topilma. |

### 6. Enterprise Architecture Audit (Pre-Phase 6) — 2026-07-28

**Manba:** To'liq loyiha auditi (migratsiyalar, RLS, Flutter arxitektura, hujjatlar)

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| (Critical darajadagi topilma aniqlanmadi) | — | Done | Claude Code | 2026-07-28 | 2026-07-28 | Audit yakunlandi, kod o'zgartirilmadi (talab qilinmagan). Natijalar keyingi Zero-Regret Audit uchun kirish ma'lumoti bo'ldi. |

### 7. Zero-Regret Audit — 2026-07-28

**Manba:** 1 million foydalanuvchi miqyosidagi arxitektura auditi (feature so'rovlari e'tiborga olinmagan)

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Maqsadli Bosqich | Izoh |
|---|---|---|---|---|---|---|
| Data Residency — O'zbekiston shaxsiy ma'lumotlari qonuni vs Supabase hosting | Critical | Open | Loyiha egasi | 2026-07-28 | Bosqich 6'dan oldin | ADR-001 orqali kuzatiladi — Bloklangan, tashqi huquqiy tasdiqlash kutilmoqda. |
| O'zgarmas audit jurnali vs ma'lumotni o'chirish so'rovlari | Critical | In Progress | Loyiha egasi | 2026-07-28 | Hisobni o'chirish feature'i | ADR-002 orqali kuzatiladi — dizayn Qabul qilingan (2026-07-28), amalga oshirish hali kutilmoqda. |
| `laws` jadvalida versiyalash yo'q — AI iqtiboslari vaqt o'tishi bilan asossiz bo'lib qoladi | High | Open | Tayinlanmagan | 2026-07-28 | Bosqich 3 (AI Service)dan oldin | ADR-003 orqali kuzatiladi — Taklif qilingan, hali qaror qabul qilinmagan. |
| AI so'rovlari uchun xarajat/suiiste'mol nazorati yo'q | High | Open | Tayinlanmagan | 2026-07-28 | Bosqich 3 (AI Service)dan oldin | ADR-004 orqali kuzatiladi — Taklif qilingan. |
| AI vendor uzilishi/fallback strategiyasi yo'q | High/Medium | Open | Tayinlanmagan | 2026-07-28 | Bosqich 3 (AI Service)dan oldin | ADR-005 orqali kuzatiladi — Taklif qilingan. |
| Offline-First talab va Phase 2/3'da qurilgan repository shartnomalari o'rtasidagi moslik aniq emas | High | Open | Tayinlanmagan | 2026-07-28 | Bosqich 4'dan oldin | ADR hali yozilmagan (`docs/adr/README.md`da ADR-006 sifatida rejalashtirilgan). |
| Ro'yxat (list) endpointlarida pagination yo'q (`listMine()` va h.k.) | High | Open | Tayinlanmagan | 2026-07-28 | Bosqich 6'dan oldin | ADR hali yozilmagan. |
| Yassi 3 rolli model (`citizen`/`organization`/`admin`) operatsion miqyoslanish chegarasi | High | Open | Tayinlanmagan | 2026-07-28 | Bosqich 5 (Admin paneli) | ADR hali yozilmagan. |
| Avtomatlashtirilgan test va CI yo'q | High | Done | Claude Code | 2026-07-28 | Bosqich 6'dan oldin | 2 ta test fayli (`test/core/`) va `.github/workflows/ci.yml` qo'shildi; GitHub Actions'da haqiqiy yashil (success) run bilan tasdiqlangan (commit `e411d0e`). |
| Fayl yuklashda magic-byte tekshiruvi yo'q, virus skanerlash yo'q, backup RPO/RTO belgilanmagan, AI vendor hosting hal qilinmagan, yagona til (o'zbek), bitta Supabase mintaqasi, push vendor tanlanmagan | Medium/Low | Open | Tayinlanmagan | 2026-07-28 | Bosqich 6 doirasida | To'liq tavsif Zero-Regret Audit hisobotida (ushbu suhbat tarixida); alohida ADR talab qilinmaydi, Bosqich 6 rejalashtirishda ko'rib chiqiladi. |

### 8. Final Project Readiness Review — 2026-07-28 (davom etmoqda)

**Manba:** Phase 6'dan oldingi yakuniy loyiha tayyorligi auditi

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| "Phase 6" atamasi ROADMAP.md'dagi rasmiy Bosqich 6 bilan chalkashtirilishi mumkin edi | Critical | Done | Claude Code | 2026-07-28 | 2026-07-28 | ROADMAP.md'ga aniq old shart va atama farqlash izohi qo'shildi. |
| ADR-001/ADR-002 hali "Taklif qilingan" holatida, Phase 6 gate qondirilmagan edi | Critical | Done | Loyiha egasi | 2026-07-28 | 2026-07-28 | ADR-002 Qabul qilingan deb belgilandi; ADR-001 Bloklangan (tashqi huquqiy javob kutilmoqda) deb aniq belgilandi. |
| Katta hajmdagi tekshirilgan/audit qilingan ish hech qachon commit qilinmagan edi | Critical | Done | Claude Code | 2026-07-28 | 2026-07-28 | 5 ta mantiqiy commit orqali (568271b, b4f3024, 43319b5, 542f9cf, 1d0cba5) barchasi commit va push qilindi. |
| `docs/ACTION_PLAN.md` hech qachon haqiqiy topilma olmagan edi | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Ushbu bo'lim (8 ta audit manbai, barcha topilmalar) yozildi va commit qilindi (`02516df`). |
| `lib/features/README.md` eskirgan ("bo'sh" deb yozilgan, 5 ta feature mavjud) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Haqiqiy 5 ta feature ro'yxati bilan yangilandi va commit qilindi (`02516df`). |
| ADR-001'da sonli xatolar bor edi (4 ta migratsiya o'rniga 5 ta; 2 ta migratsiya o'rniga 3 ta, 26 siyosat o'rniga 38) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | ADR-001'dagi ikkala raqamli xato tuzatildi (commit `b7dae30`). |
| ROADMAP.md ADR jarayoniga umuman ishora qilmaydi | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | ROADMAP.md'ga `docs/adr/README.md`ga ikkita o'zaro havola qo'shildi (commit `b7dae30`). |
| `android`/`ios`/`web` commit qilinishi kerakmi degan qoida SETUP.md va .gitignore o'rtasida hal qilinmagan | High | Done | Loyiha egasi | 2026-07-28 | 2026-07-28 | Qoida amalda hal qilindi (papkalar commit `1d0cba5`da qo'shilgan); SETUP.md shu holatga mos yangilandi (commit `b7dae30`). |
| Avtomatlashtirilgan test va CI yo'q (Zero-Regret Audit bilan bir xil topilma) | High | Done | Claude Code | 2026-07-28 | 2026-07-28 | Yuqoridagi 7-bo'limdagi bir xil yozuvga qarang — ikkalasi bir xil tuzatish bilan yopildi, ikki marta hisoblanmaydi. |
| `pubspec.lock` avval kuzatilmagan edi | Medium | Done | Claude Code | 2026-07-28 | 2026-07-28 | Blocker #3 doirasida commit qilindi (`1d0cba5`). |
| 12 ta eski RLS siyosati hali yangi funksiyalarga o'tkazilmagan | Medium | Open | Tayinlanmagan | 2026-07-28 | — | Xatti-harakat to'g'ri, faqat izchillik masalasi; shoshilinch emas. |
| Bog'liqliklar versiyasi eskirgan (36 ta paket) | Medium | Open | Tayinlanmagan | 2026-07-28 | — | Oddiy texnik xizmat, shoshilinch emas. |

### 9. Loyiha auditi qayta baholovi (Module 5 Phase 5C yakunida) — 2026-07-30

**Manba:** `PROJECT_AUDIT.md` qayta baholovi (80/100), 2026-07-26 skeleton auditidan keyingi birinchi to'liq qayta ko'rib chiqish

| Topilma | Ustuvorlik | Holati | Owner | Ochilgan | Yopilgan | Izoh |
|---|---|---|---|---|---|---|
| `LogInterceptor` release build'da ham faol (`lib/services/network/dio_client.dart:21`) — `kDebugMode` guard yo'q | High | **Done** | Claude Code | 2026-07-26 | 2026-07-30 | Interceptor `if (kDebugMode)` ichiga olindi — release'da tree-shaking uni butunlay olib tashlaydi (sozlamani yumshatish emas, umuman qo'shmaslik: URL'ning o'zi ham ma'lumot). `lib/` bo'ylab bir xil sinfdagi boshqa oqish yo'qligi tekshirildi. `test/core/release_logging_safety_test.dart` qoidani CI'ga bog'ladi; guard vaqtincha olib tashlanganda 3 testdan 2 tasi qizil bo'lishi tasdiqlandi. Commit `ef0dbae`. |
| `lib/features/` uchun bitta ham avtomatik test yo'q (108 fayl / 0 test) | High | **Done** | Claude Code | 2026-07-30 | 2026-07-30 | `test/helpers/` infratuzilmasi (Result matcher'lari, Supabase fixture'lari, qo'lda yozilgan fake'lar — mock kutubxonasiz) + 70 ta test: `AuthRepositoryImpl` (20), `mapSupabaseExceptionToFailure` (14), `AppealsRepositoryImpl` (12), usecase simlari (12), `ProfileModel` (8), birinchi widget testi (4). 371 → 441 test. Mutatsiya bilan tasdiqlandi: mapper'dan RLS tarmog'i olib tashlanganda 3 faylda 5 test qizil bo'ladi. Commit `a93d191`. |
| Widget/integration test yo'q — "No Dead End Rule" avtomatik tekshirilmaydi | Medium | **In Progress** | Claude Code | 2026-07-30 | — | Widget test infratuzilmasi o'rnatildi (`appeal_status_badge_test.dart`, commit `a93d191`), lekin presentation qatlami (`auth_providers.dart`, ekranlar) va oqim darajasidagi integration testlar hali yo'q. |
| `ai_service/` (7 821 qator) uchun ishga tushirish muhiti hali tanlanmagan | High | Open | Tayinlanmagan | 2026-07-30 | — | ADR-006 doirasida; kod hozircha faqat testda ishlaydi. Qaror kechikkan sari kontrakt haqiqatga mos kelmaslik xavfi oshadi. |
| `.env.example` yo'q; `.gitignore`dagi `!.env.example` istisnosi hech narsaga ishora qilmaydi | Medium | Open | Tayinlanmagan | 2026-07-26 | — | 2026-07-26 auditidan qolgan, ACTION_PLAN.md'ga endi yozildi. |
| `main.dart`da global xatolik ushlash (`FlutterError.onError`) ulanmagan | Medium | Open | Tayinlanmagan | 2026-07-26 | — | Crash-reporting integratsiyasi uchun tayyor joy yo'q. |
| Barcha 87 fayl nisbiy import ishlatadi, absolyut import hech qayerda yo'q | Medium | Open | Tayinlanmagan | 2026-07-26 | — | Loyiha 159 faylga o'sgani sababli refaktoring xarajati oshdi. |
| `lib/`da markazlashgan DI composition root yo'q | Low | Open | Tayinlanmagan | 2026-07-26 | — | Naqsh loyihada bor (`ai_service/di/`), lekin ilova tomonida qo'llanmagan. |
| `PROJECT_AUDIT.md` 4 kun eskirgan edi (skeleton holatini ko'rsatardi) | Medium | Done | Claude Code | 2026-07-30 | 2026-07-30 | Hujjat Module 5 Phase 5C holatiga to'liq yangilandi: bajarilgan modullar jadvali, yangilangan baholash mezoni (80/100), reliz tayyorligi jadvali, qolgan ishlar ro'yxati va oldingi topilmalar holati qo'shildi. |
| `docs/ROADMAP.md`, "Joriy amalga oshirish holati" bo'limi 2026-07-28'da qotgan (Module 4/5 aks etmagan) | Low | Open | Tayinlanmagan | 2026-07-30 | — | Hujjat-kod muvofiqligi talabi (Release Criteria) uchun Bosqich 6'dan oldin yangilanishi kerak. |

## Empty template for future actions

Yangi audit topilmasi qo'shishda quyidagi shablondan nusxa olib to'ldiring:

```
### [Topilma nomi]

- **Manba (audit turi va sanasi):**
- **Tavsif:**
- **Qayerda aniqlangan:**
- **Ustuvorlik:** (Critical / High / Medium / Low)
- **Holati:** (Open / In Progress / Done)
- **Mas'ul shaxs (Owner):**
- **Maqsadli Sprint/Bosqich:**
- **Ochilgan sana:**
- **Yopilgan sana:**
- **Yechim izohi:**
```

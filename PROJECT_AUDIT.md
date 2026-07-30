# Adolat AI — Loyiha Auditi

**Sana:** 2026-07-30 (qayta baholov: ikkita High topilma yopilgandan keyin)
**Auditor:** Claude Code (avtomatik audit)
**Holat:** Module 5, Phase 5C yakunlangan + audit tuzatishlari — commit `a93d191`, GitHub Actions yashil.
**Oldingi audit:** 2026-07-26 (skeleton bosqichi, 79/100) — quyidagi "Oldingi audit topilmalari holati" bo'limiga qarang.

**Ko'lam:** Repozitoriyaning joriy holati — 49 commit, `lib/` (159 fayl / 14 693 qator), `ai_service/` (131 fayl / 7 821 qator), `test/` (83 fayl / 8 239 qator, **441 test**), 5 ta Supabase migratsiyasi, 18 ta hujjat va 6 ta ADR.

**Ushbu qayta baholovda yopilgan ikkita High topilma:**

| Topilma | Commit | Natija |
|---|---|---|
| `LogInterceptor` release build'da ham faol | `ef0dbae` | `kDebugMode` guard + `release_logging_safety_test.dart` (regressiya qulfi) |
| `lib/features/` uchun bitta ham test yo'q | `a93d191` | Test infratuzilmasi (`test/helpers/`) + 70 ta yangi test |

## Metodologiya

Baholash **tekshirilgan dalilga** tayanadi, hujjatdagi da'voga emas. Har bir band uchun:

- kod bevosita o'qildi yoki `grep` bilan tekshirildi (masalan `kDebugMode` mavjudligi, import turlari, test taqsimoti);
- `flutter analyze` va `flutter test` haqiqatan ishga tushirildi (natijalar quyida);
- hujjatdagi tasdiq (masalan "RLS joriy etilgan") migratsiya fayllari bilan solishtirildi.

**Muhim o'zgarish — baholash mezoni yangilandi.** 2026-07-26 auditi biznes logikasi YO'Q skeleton uchun tuzilgan edi (5 bo'lim: arxitektura / papka / nomlash / xavfsizlik / kengaytirish). Bugungi loyihada 22 000+ qator kod bor, shuning uchun **test va sifat darvozasi** hamda **hujjatlashtirish** alohida bo'lim sifatida qo'shildi, "papka" va "nomlash" esa bitta bo'limga birlashtirildi. Shu sababli **79 → 80 taqqoslash to'g'ridan-to'g'ri emas** — bu boshqa o'lchov chizg'ichi, ikkalasi ham 100 ballik, lekin bo'limlar boshqacha.

---

## Bajarilgan modullar

`docs/ROADMAP.md`dagi rasmiy "Bosqich" tizimi va amaliy qurilish tartibi farq qiladi (ROADMAP, "Joriy amalga oshirish holati" bo'limi buni hujjatlashtiradi). Quyida **haqiqatan commit qilingan** ish:

| Modul / Bosqich | Mazmuni | Commit | Holat |
|---|---|---|---|
| Bosqich 0 | Hujjatlash (vision, arxitektura, DB, xavfsizlik, UI, roadmap) + Dart skeleti | `c6a1c0d`–`4eb9150` | ✅ Yakunlangan |
| Backend poydevori | 5 ta migratsiya: sxema, RLS siyosatlari, Storage, auth trigger, avtorizatsiya markazlashtirish | `bd154a4`–`568271b` | ✅ Yakunlangan |
| Bosqich 2/3 (UI qismi) | `appeals` + `disputes` Clean Architecture 3 qatlami | `542f9cf` | ✅ Yakunlangan |
| Module 1–3 (auth) | Domain → data → presentation, GoRouter auth guard, rolga asoslangan navigatsiya | `9256018`, `da84cca`, `2ac40bd`, `8902849` | ✅ Yakunlangan |
| Module 4, Phase 1–2C | AI Service poydevori: entity'lar, suhbat yadrosi, context engine, orkestratsiya/retry/xatolik | `79b8798`–`5fef853` | ✅ Yakunlangan |
| Module 4, Phase 3A–3B | Protokol (simli shartnoma) + gateway (auth/dispatch/timeout/transport) | `4b65564`, `b527bd2` | ✅ Yakunlangan |
| Module 4, Phase 4A | Klient integratsiya poydevori (`lib/core/ai_client/`) | `3c5d525` | ✅ Yakunlangan |
| Module 4, Phase 4B–4C | Backend kontrakti (kvota/rate-limit/persistensiya/fayl) + ijro zanjiriga ulanish | `1aa90cb`, `10955b8` | ✅ Yakunlangan |
| Module 5, Phase 5A | AI konfiguratsiya va boshqaruv (provayder/limit/xarajat, kalitsiz) | `3bb8758` | ✅ Yakunlangan |
| Module 5, Phase 5B | Case va suhbat poydevori (lifecycle, intake, timeline) | `c6ebc5b` | ✅ Yakunlangan |
| **Module 5, Phase 5C** | **Yordam oqimi: aniqlashtirish → to'liqlik → tavsiya → tartibli reja → progress** | **`2eab9a3`** | ✅ **Yakunlangan** |

**Module 5 (5A–5C) yakuniy holati:** AI qatlamining butun poydevori — konfiguratsiya, ish (case) modeli va yordam oqimi — qurilgan va 371 test bilan qoplangan. Hech qanday haqiqiy AI provayderi, API kaliti yoki huquqiy xulosa mantig'i yo'q; bularning hammasi ataylab almashtiriladigan chegaralar ortida qoldirilgan.

---

## 1. Arxitektura

**Kuchli tomonlar:**

- Clean Architecture 6 ta feature'da (`auth`, `appeals`, `disputes`, `ai_analyses`, `attachments`, `legal_reference`) izchil qo'llangan — `data`/`domain`/`presentation` chegarasi hech qayerda buzilmagan.
- `ai_service/`ning `lib/`dan mustaqilligi **avtomatik test bilan** majburlangan (`test/ai_service/architecture_boundary_test.dart`) — bu chegara endi kod ko'rib chiqish intizomiga emas, CI'ga tayanadi.
- Module 5, Phase 5C xuddi shu yondashuvni kengaytirdi: `workflow_provider_independence_test.dart` yordam oqimi qatlamiga provayder/gateway/protokol/kalit kirib kelishini bloklaydi.
- Almashtirish nuqtalari aniq va hujjatlashtirilgan (`AIProviderAdapter`, `CaseIntakeAssistant`, `RecommendationEngine`, `InformationCompletenessEvaluator`) — haqiqiy AI kelganda chaqiruvchi kod o'zgarmaydi.
- `Failure` sealed union (`lib/core/error/failure.dart`) va `describeErrorForUser()` zanjiri qurilgan — 2026-07-26 auditidagi bo'shliq yopilgan.

**Aniqlangan bo'shliqlar:**

1. **Offline-First umuman qurilmagan.** `docs/ROADMAP.md` buni "muzokara qilinmaydigan (non-negotiable) minimal talab" deb belgilaydi (Release Criteria), lekin `lib/`da na Local Storage, na Sync Engine, na Network State Handling mavjud. Bu rejalashtirilgan tartibga mos (Bosqich 4), lekin MVP uchun eng katta ochiq arxitektura bloki.
2. **`lib/`da markazlashgan DI "composition root" yo'q** (`lib/core/di/` mavjud emas) — providerlar `services/` va feature'lar ichida tarqoq. Qiziq holat: `ai_service/di/ai_service_locator.dart` mavjud, ya'ni naqsh loyihada allaqachon bor, lekin ilova tomonida qo'llanmagan.
3. **`main.dart`da global xatolik ushlash yo'q** — `FlutterError.onError` va `PlatformDispatcher.instance.onError` ulanmagan (2026-07-26 auditidan beri o'zgarmagan). Crash-reporting uchun tayyor joy yo'q.

**Baho: 22/25**

---

## 2. Xavfsizlik

**Kuchli tomonlar:**

- **RLS to'liq joriy etilgan** — 5 ta migratsiya, barcha 13 jadvalda yoqilgan, egalik tekshiruvi `is_admin()`/`owns_appeal()`/`is_dispute_party()`/`can_access_case()` funksiyalarida markazlashtirilgan (2026-07-26 auditidagi **eng kritik** topilma yopilgan).
- Storage yo'llarida UUID formatini cast'dan oldin tekshiruvchi guard.
- Hech qanday maxfiy qiymat kodda yo'q; `--dart-define` orqali; tokenlar `flutter_secure_storage`da.
- `ai_service/` API kalitini **hech qachon** o'zida saqlamaydi — faqat `AICredentialReference` (ishora), yechish esa implementatsiyasiz interfeys ortida.
- Sezgir ma'lumotni loglamaslik intizomi izchil: `AIBackendCredential`, `Case`, `CollectedInformation`ning `toString()`lari maskalaydi — har biri test bilan qulflangan.
- Phase 5C'ning **beshta usecase'ining hammasi** `GetCaseUseCase` orqali egalik tekshiruvidan o'tadi; har biri uchun alohida test bor.

- ✅ **Release loglash oqishi yopildi** (`ef0dbae`): `LogInterceptor` endi `if (kDebugMode)` ichida — release build'da tree-shaking uni butunlay olib tashlaydi. `lib/` bo'ylab bir xil sinfdagi boshqa oqish yo'qligi tekshirildi (qolgan ikkita logger allaqachon to'g'ri himoyalangan, xom `print()` yo'q). `test/core/release_logging_safety_test.dart` qoidani CI'ga bog'ladi — tuzatish vaqtincha bekor qilinganda 3 testdan 2 tasi qizil bo'lishi tasdiqlangan.

**Aniqlangan bo'shliqlar (muhimlik tartibida):**

1. 🟠 **`.env.example` hamon yo'q** — yangi dasturchi kerakli environment o'zgaruvchilarini faqat `env_config.dart`ni o'qib biladi. `.gitignore`dagi `!.env.example` istisnosi hanuz hech narsaga ishora qilmaydi.
3. 🟠 **ADR-001 (Data Residency) — Bloklangan.** O'zbekiston shaxsiy ma'lumotlar qonuni vs Supabase hosting masalasi tashqi huquqiy tasdiqlashni kutmoqda. Bu `docs/adr/README.md`dagi Bosqich 6 gate'ini **qondirilmagan** holda ushlab turadi. Claude Code buni hal qila olmaydi — loyiha egasining vazifasi.
3. 🟡 Sertifikat pinning (certificate pinning) qarori hamon qabul qilinmagan.

**Baho: 18/20** *(oldingi baholovda 15/20 — release loglash oqishi yopilgani uchun +3)*

---

## 3. Test va sifat darvozasi

*(Yangi bo'lim — 2026-07-26 auditida mavjud emas edi, chunki o'shanda kod ham, test ham yo'q edi.)*

**Kuchli tomonlar:**

- **441 test, hammasi yashil**; CI (`.github/workflows/ci.yml`) har `push`/`pull_request`da `flutter analyze` + `flutter test` ishga tushiradi.
- Testlar shunchaki "qamrov" emas — **arxitektura invariantlarini qulflaydi**: Flutter/`lib` chegarasi, provayder mustaqilligi, kalit ishlatilmasligi, sezgir ma'lumot loglanmasligi, release loglash taqiqi, tartib invariantlari.
- `ai_service/` deyarli to'liq qoplangan (61 test fayli, 131 manba fayliga).
- ✅ **`lib/features/` endi qoplangan** (`a93d191`): qayta ishlatiladigan infratuzilma (`test/helpers/` — `Result` matcher'lari, Supabase fixture'lari, qo'lda yozilgan fake'lar; mock kutubxonasi qo'shilmadi) va 70 ta yangi test.
- Qamrov **xato qilish mumkin bo'lgan** joyga yo'naltirilgan, fayl soniga emas: feature usecase'lari 12–27 qatorlik sof delegatsiya (biznes qoidalari RLS'da, server tomonida), shuning uchun asosiy e'tibor `AuthRepositoryImpl` (ikki jadvalni birlashtirish, sessiya talqini), `mapSupabaseExceptionToFailure` (butun ilovadagi har bir `catch` bloki shuni chaqiradi) va `@JsonKey` xaritalashiga qaratilgan.
- Test to'plami **bo'sh emasligi tasdiqlangan**: mapper'dan RLS (`42501`) tarmog'i vaqtincha olib tashlanganda uchta faylda 5 ta test qizil bo'ladi.

**Aniqlangan bo'shliqlar:**

1. 🟠 **Presentation qatlami deyarli qoplanmagan** — `auth_providers.dart` (216 qator, holat boshqaruvi) va ekranlar (`*_screen.dart`, 150–272 qator) hali testsiz. Bitta widget testi (`AppealStatusBadge`) faqat INFRATUZILMANI o'rnatdi.
2. 🟠 **Integration/end-to-end test yo'q** — "No Dead End Rule" (`DEVELOPMENT_RULES.md`, 17–19-band) va auth guard xatti-harakati hamon faqat qo'lda tekshirilishi mumkin.
3. 🟡 `DisputesRepositoryImpl` bevosita qoplanmagan (usecase simlari va entity darajasida bilvosita tekshiriladi) — `AppealsRepositoryImpl` bilan bir xil naqsh, shuning uchun xavf past.
4. 🟡 Test qamrovi o'lchanmaydi (`--coverage` CI'da ishlatilmaydi).

**Baho: 17/20** *(oldingi baholovda 13/20 — `lib/features/` qamrovi ochilgani uchun +4; presentation qatlami hali ochiq bo'lgani uchun to'liq ball emas)*

---

## 4. Kengaytirish imkoniyati

**Kuchli tomonlar:**

- Namunaviy (reference) feature muammosi yopilgan — `auth` to'liq uch qatlamli jonli namuna, `appeals`/`disputes` uni takrorlaydi.
- AI qatlami provayderdan mustaqil: yangi provayder qo'shish uchun faqat `AIProviderAdapter` implementatsiyasi kerak (`ADR-005`).
- Phase 5C mazmun (savol matni, tavsiya) bilan tuzilmani (tartib, invariant) ajratdi — haqiqiy AI kelganda faqat mazmun manbai almashadi.
- DRY intizomi kuzatilmoqda: 5C'da `MockCaseIntakeAssistant` savollari umumiy katalogga ko'chirildi, ikkita bir xil enum o'rniga bitta `NextStepKind` ishlatildi.

**Aniqlangan bo'shliqlar:**

1. 🟠 **Barcha 87 fayl nisbiy import ishlatadi**, `package:adolat_ai/...` absolyut import **hech qayerda** yo'q (2026-07-26 auditidan beri o'zgarmagan). Loyiha 159 faylga o'sgani sababli, fayl ko'chirish endi ancha qimmatroq operatsiyaga aylandi.
2. 🟠 Ro'yxat endpointlarida pagination yo'q (`listMine()` va h.k.) — Zero-Regret Auditda qayd etilgan, hanuz ochiq.
3. 🟡 `ai_service/` uchun ishga tushirish muhiti (Edge Function yoki alohida Dart xizmati) hali tanlanmagan — 7 821 qator kod hozircha **hech qayerda ishlamaydi**, faqat testda. Bu ataylab (`ADR-006`), lekin qaror qancha kechiksa, kontrakt haqiqatga mos kelmasligi xavfi shuncha oshadi.

**Baho: 12/15**

---

## 5. Hujjatlashtirish

*(Yangi bo'lim — hujjat sifati loyihaning eng kuchli tomoni bo'lgani uchun alohida o'lchanadi.)*

**Kuchli tomonlar:**

- 18 ta hujjat + 6 ta ADR; `docs/AI_ARCHITECTURE.md` yolg'iz o'zi 1 400+ qator, diagrammalar va talab→kod xaritalari bilan.
- Har bir arxitektura qarori **sababi bilan** yozilgan ("nega Freezed emas", "nega interfeys", "nega ikkita enum emas") — bu kod izohlarida ham izchil davom etadi.
- `docs/ACTION_PLAN.md` 8 ta audit manbaidan topilmalarni kuzatadi, yozuvlar o'chirilmaydi.
- Hujjat-kod muvofiqligi faol saqlanadi (`b4f3024`, `02516df` — eskirgan hujjatlarni tuzatish uchun maxsus commitlar).

**Aniqlangan bo'shliqlar:**

1. 🟠 **`PROJECT_AUDIT.md`ning o'zi 4 kun eskirgan edi** — 2026-07-26 skeleton auditini ko'rsatib turardi, holbuki oradan 30+ commit va butun Module 4/5 o'tgan. Ushbu yangilanish shu bo'shliqni yopadi.
2. 🟡 `docs/ROADMAP.md`, "Joriy amalga oshirish holati" bo'limi 2026-07-28 sanasida qotgan — Module 4/5 (AI Service poydevori) unda aks etmagan.
3. 🟡 Fayl-suffiks konventsiyasi (`*_service`, `*_client`, `*_usecase`, `*_repository`) hech qayerda yagona jadval sifatida yozilmagan.

**Baho: 9/10**

---

## 6. Papka tuzilishi va nomlash

**Kuchli tomonlar:**

- Nomlash izchil: `snake_case.dart`, `PascalCase`, `camelCaseProvider`; `abstract final class` statik-only klasslar uchun.
- `ai_service/` ildizda, `lib/`dan tashqarida — sabab hujjatlashtirilgan va test bilan majburlangan.
- 46 commitda konvensional commit uslubi (`feat(scope):`, `fix(scope):`, `docs:`) buzilmagan.

**Aniqlangan bo'shliqlar:**

1. 🟡 `lib/models/` va `lib/shared/` orasidagi chegara hanuz nazariy (2026-07-26 topilmasi) — amalda ikkalasi ham kam ishlatilgani uchun muammo yuzaga chiqmagan.

**Baho: 9/10**

---

## Yakuniy baho

| Bo'lim | Ball | Maksimal | Oldingi (2026-07-30, tuzatishlardan oldin) |
|---|---:|---:|---:|
| 1. Arxitektura | 22 | 25 | 22 |
| 2. Xavfsizlik | 18 | 20 | 15 |
| 3. Test va sifat darvozasi | 17 | 20 | 13 |
| 4. Kengaytirish imkoniyati | 12 | 15 | 12 |
| 5. Hujjatlashtirish | 9 | 10 | 9 |
| 6. Papka tuzilishi va nomlash | 9 | 10 | 9 |
| **Jami** | **87** | **100** | **80** |

### Talqin

**87/100 — "Ikkala High topilma yopildi; qolgan bo'shliqlar endi asosan QURILMAGAN bosqichlar (offline-first, admin) va tashqi bloker."**

Loyiha 2026-07-26 dagi skeletondan 22 000+ qatorli, CI bilan himoyalangan, ADR asosida boshqariladigan kod bazasiga o'sdi. Eng kuchli tomoni — **qaror sababi hujjatlashtiriladi va arxitektura chegaralari test bilan qulflanadi**.

Bu qayta baholovda ikkala High topilma **shunchaki tuzatilmadi, balki qaytib kelmasligi ta'minlandi**: har biri o'ziga tegishli regressiya testi bilan CI'ga bog'landi, va ikkala test ham ataylab buzish (mutatsiya) orqali haqiqatan ishlashi tasdiqlandi. Bu muhim, chunki `LogInterceptor` topilmasi aynan "faqat kod ko'rib chiqishga tayanish" sababli 4 kun va ikkita audit davomida ochiq qolgan edi.

**95 ballga yetish uchun qolgan asosiy to'siqlar** (`DEVELOPMENT_RULES.md`, 23-band) — endi ularning hech biri "e'tibordan chetda qolgan qarz" emas, balki rejalashtirilgan ish yoki tashqi qaror:

1. **Bosqich 4 (Offline-First)** — MVP'ning muzokara qilinmaydigan talabi, hali boshlanmagan (arxitektura bo'limidagi eng katta chegirma).
2. **Presentation qatlami testlari** — infratuzilma tayyor, endi kengaytirish arzon.
3. **ADR-001** — Claude Code hal qila olmaydigan yagona bloker (huquqiy tasdiqlash, loyiha egasi).

### Reliz tayyorligi

`docs/ROADMAP.md`, "Release Criteria" bo'yicha:

| Mezon | Holat |
|---|---|
| Funksional to'liqlik (2 oqim × 3 rol) | ⚠️ Qisman — appeals/disputes UI bor, admin paneli yo'q |
| Offline-first | ❌ Boshlanmagan (Bosqich 4) |
| Xavfsizlik audit talabi | ✅ **Critical/High ochiq topilma yo'q** (log oqishi yopildi) |
| Audit balli ≥ 95 | ❌ 87/100 |
| RLS to'liq qamrovi | ✅ 13/13 jadval |
| No Dead End Rule | ⚠️ `Failure` → foydalanuvchi xabari zanjiri endi test bilan qoplangan; oqim darajasidagi tekshiruv hamon qo'lda |
| Hujjat-kod muvofiqligi | ✅ |
| Barcha topilmalar yopilgan | ⚠️ Critical/High yo'q; Medium/Low ochiq yozuvlar bor |

**Xulosa: loyiha reliz nomzodi (M6) holatidan uzoq va rasmiy Bosqich 6'ni boshlashga tayyor emas** — Bosqich 4 (offline-first) va Bosqich 5 (admin/push) hali qurilmagan, ADR gate qondirilmagan.

### Qolgan ishlar (ustuvorlik bo'yicha)

| # | Ish | Ustuvorlik | Bog'liq |
|---|---|---|---|
| ~~1~~ | ~~`LogInterceptor`ni debug rejimi bilan cheklash~~ | ✅ **Yopildi** (`ef0dbae`) | `DEVELOPMENT_RULES.md` 11-band |
| ~~2~~ | ~~`lib/features/` uchun test infratuzilmasi va testlar~~ | ✅ **Yopildi** (`a93d191`) | Release Criteria, audit balli |
| 3 | ADR-001 huquqiy tasdiqlash (loyiha egasi) | High | Bosqich 6 gate |
| 4 | `ai_service/` uchun ishga tushirish muhitini tanlash va ulash | High | ADR-006, Bosqich 3 yakuni |
| 5 | Bosqich 4 — Offline-First (Local Storage, Sync Engine, Conflict Resolution) | High | MVP majburiy talabi |
| 6 | Bosqich 5 — Admin paneli va push xabarnomalar | Medium | M5 |
| 7 | `.env.example` qo'shish | Medium | Onboarding |
| 8 | Global xatolik ushlash (`FlutterError.onError`) | Medium | Crash-reporting |
| 9 | Absolyut importlarga o'tish | Medium | Refaktoring xarajati |
| 10 | Pagination (`listMine()` va h.k.) | Medium | Zero-Regret Audit |
| 11 | `lib/core/di/` composition root | Low | Izchillik |
| 12 | ADR-003/004/005 bo'yicha qaror | Low | Hozircha bloklamaydi |

Ushbu auditda aniqlangan yangi topilmalar `docs/DEVELOPMENT_RULES.md`, 25-bandga muvofiq `docs/ACTION_PLAN.md`ga (9-bo'lim) yozildi.

---

## Oldingi audit topilmalari holati (2026-07-26 → 2026-07-30)

| 2026-07-26 topilmasi | Holat |
|---|---|
| `core/error/`da `Failure` bazaviy klassi yo'q | ✅ Yopilgan — `failure.dart` + `failure_presentation.dart` |
| Markazlashgan DI composition root yo'q | ⚠️ Qisman — `ai_service/di/` bor, `lib/` uchun hanuz yo'q |
| `app_router.dart`da auth guard yo'q | ✅ Yopilgan — reaktiv guard (`authStateChangesProvider` + `refreshListenable`) |
| `main.dart`da global xatolik ushlash yo'q | ❌ Ochiq |
| `pubspec.yaml` SDK versiyasi taxminiy | ✅ Yopilgan — Flutter 3.44.8 bilan tekshirilgan, `pubspec.lock` commit qilingan |
| Test namuna strukturasi yo'q | ✅ Yopilgan — `test/helpers/` infratuzilmasi + `test/features/` (441 test) |
| `.env.example` yo'q / `.gitignore` nomuvofiqligi | ❌ Ochiq |
| **`LogInterceptor` release'da ham faol** | ✅ **Yopilgan** — `kDebugMode` guard + regressiya testi (`ef0dbae`) |
| **Supabase RLS hujjatlashtirilmagan/joriy etilmagan** | ✅ **Yopilgan** — 5 migratsiya, markazlashgan funksiyalar |
| Sertifikat pinning hujjatlashtirilmagan | ❌ Ochiq |
| Namunaviy (reference) feature yo'q | ✅ Yopilgan — `auth` |
| CI/CD yo'q | ✅ Yopilgan — `.github/workflows/ci.yml`, yashil |
| `CHANGELOG.md` yo'q | ❌ Ochiq (Low) |
| Nisbiy importlar | ❌ Ochiq |
| Fayl-suffiks konventsiyasi jadvali yo'q | ❌ Ochiq (Low) |

**Yopilgan: 8 · Qisman: 1 · Ochiq: 6** — 2026-07-26 auditining **ikkala eng kritik bandi** (RLS va `LogInterceptor`) endi yopilgan. Qolgan ochiq bandlar Medium/Low darajada va hech biri reliz blokeri emas.

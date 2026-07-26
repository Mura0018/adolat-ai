# Adolat AI — Loyiha Auditi

**Sana:** 2026-07-26
**Auditor:** Claude Code (avtomatik audit)
**Ko'lam:** Repozitoriyadagi barcha hujjatlar (`README.md`, `docs/*.md`, har bir papkadagi `README.md`) va barcha `.dart`/konfiguratsiya fayllari o'qib chiqildi. Bu **faqat audit** — hech qanday fayl o'zgartirilmadi yoki qo'shilmadi (ushbu hisobot fayli bundan mustasno).

## Metodologiya

Quyidagi fayllar to'liq o'qildi:

- `README.md`, `docs/architecture.md`, `docs/folder_structure.md`, `docs/setup.md`
- `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`, `.gitignore`
- `lib/main.dart`, `lib/app.dart`
- `lib/core/config/env_config.dart`
- `lib/services/network/dio_client.dart`, `lib/services/supabase/supabase_client.dart`, `lib/services/secure_storage/secure_storage_service.dart`
- `lib/router/app_router.dart`, `lib/router/route_paths.dart`
- `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`, `lib/theme/app_typography.dart`
- `lib/localization/app_uz.arb`, `lib/localization/app_en.arb`
- Har bir papkadagi (`core/`, `features/`, `shared/`, `services/`, `models/`, `widgets/`) `README.md` fayllari

Loyiha hozircha **skeleton bosqichida** — biznes logika yo'q. Baholash shu kontekstda, ya'ni "keyingi rivojlanish uchun poydevor qanchalik puxta" nuqtai nazaridan qilindi.

---

## 1. Arxitektura

**Yondashuv:** Feature-first + Clean Architecture (`data` / `domain` / `presentation`), `docs/architecture.md`da to'liq tushuntirilgan. Bog'liqlik yo'nalishi to'g'ri hujjatlashtirilgan: `presentation → domain ← data`.

**Kuchli tomonlar:**
- Qatlamlar orasidagi mas'uliyat chegarasi aniq (domain sof Dart, tashqi paketlarga bog'liq emas)
- Xatolik boshqaruvi konventsiyasi (`Exception → Failure`) oldindan belgilangan
- Riverpod orqali DI/holat boshqaruvi izchil tanlangan

**Aniqlangan bo'shliqlar:**
- `core/error/` papkasida haqiqiy `Failure` bazaviy klassi hali yo'q — faqat `docs/architecture.md`da misolda tilga olingan. Birinchi feature yozuvchisi buni noldan yaratishga majbur bo'ladi, bu konvensiyadan chetga chiqish xavfini oshiradi.
- Markazlashgan DI "composition root" yo'q (masalan `core/di/`) — providerlar `services/` ichida tarqoq e'lon qilingan. Kichik loyihada muammo emas, lekin feature soni oshganda providerlarni bir joydan ko'rib chiqish qiyinlashadi.
- `app_router.dart`da auth guard/redirect strukturasi yo'q (kutilgan holat, chunki auth feature hali yo'q, lekin kelgusida qo'shilishi rejalashtirilishi kerak).
- `main.dart`da global xatolik ushlash (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) ulanmagan — crash-reporting integratsiyasi uchun tayyor joy yo'q.
- `pubspec.yaml`dagi `sdk: '>=3.5.0 <4.0.0'` — Flutter SDK bu muhitda o'rnatilmagani sababli taxminiy qiymat; birinchi `flutter pub get`dan oldin haqiqiy SDK versiyasiga moslab tekshirish kerak.

**Baho: 21/25**

---

## 2. Papkalar va fayl tuzilishi

**Kuchli tomonlar:**
- So'ralgan barcha papkalar (`core, features, shared, services, models, widgets, theme, router, localization, assets, docs`) mavjud va har birida vazifasini tushuntiruvchi `README.md` bor.
- `assets/` va `docs/` to'g'ri holda repo ildizida (Flutter konventsiyasiga mos), `lib/` ichidagilar Dart kod papkalari.

**Aniqlangan bo'shliqlar:**
- `lib/models/` va `lib/shared/` orasidagi chegara ba'zida noaniq bo'lishi mumkin (ikkalasi ham "bir nechta feature uchun umumiy" narsalarni saqlaydi) — README'larda farq tushuntirilgan, lekin amalda intizomni saqlash jamoa kattalashganda qiyinlashishi mumkin.
- `.gitignore`da `.env.example` uchun istisno (`!.env.example`) bor, lekin loyiha `.env` fayldan emas, `--dart-define`dan foydalanadi (`docs/setup.md`, 6-band). Bu ikki yondashuv orasida nomuvofiqlik — yo `.env.example` namunasi qo'shilishi, yoki gitignoredagi shu qator olib tashlanishi kerak.
- Test uchun namuna struktura (`test/features/...`) hali yaratilmagan — bu qasddan (biznes logika yo'q), lekin birinchi feature qo'shilganda test papkasi qanday shakllanishi aniq emas.

**Baho: 17/20**

---

## 3. Nomlash konventsiyalari

**Kuchli tomonlar:**
- Fayllar izchil `snake_case.dart`, klasslar `PascalCase`, providerlar `camelCaseProvider` shaklida.
- Statik-only klasslar uchun zamonaviy Dart 3 patterni (`abstract final class`) izchil qo'llangan (`EnvConfig`, `AppTheme`, `AppColors`, `SupabaseService`, `RoutePaths`).
- Provider nomlanishi klass nomiga mos (`SecureStorageService` → `secureStorageServiceProvider`).

**Aniqlangan bo'shliqlar:**
- Barcha import'lar nisbiy yo'l (`../../core/config/env_config.dart`) orqali yozilgan, `package:adolat_ai/...` absolyut import ishlatilmagan. Loyiha kattalashganda fayllarni ko'chirish/refaktoring qilishda nisbiy importlar ko'proq xato beradi — enterprise Dart loyihalarida odatda absolyut import afzal ko'riladi.
- `route_paths.dart` boshqa `*_service.dart`/`*_client.dart` fayllaridan farqli, "Paths" so'zi bilan tugaydi — mazmunan to'g'ri, lekin loyiha bo'yicha fayl-suffiks konventsiyasi (`*_service`, `*_client`, `*_config`, `*_paths`) hech qayerda yagona jadval sifatida hujjatlashtirilmagan.

**Baho: 12/15**

---

## 4. Xavfsizlik

**Kuchli tomonlar:**
- Hech qanday maxfiy qiymat (Supabase kaliti, API manzili) kodga qattiq yozilmagan — barchasi `String.fromEnvironment` orqali build vaqtida beriladi.
- `.gitignore` `.env`, `.env.*` fayllarni to'g'ri istisno qiladi.
- Maxfiy ma'lumotlar uchun `SharedPreferences` emas, platforma darajasidagi xavfsiz xotira (`flutter_secure_storage`) tanlangan.
- `analysis_options.yaml`da `avoid_print: true` — production kodda tasodifiy `print()` orqali ma'lumot sizib chiqishining oldini oladi.

**Aniqlangan bo'shliqlar (muhimlik tartibida):**
1. **`dio_client.dart`dagi `LogInterceptor` build rejimidan qat'i nazar doimo faol** (`kDebugMode` tekshiruvi yo'q). Bu hozircha so'rov/javob tanasini logga yozmaydi (`requestBody: false, responseBody: false`), lekin so'rov URL'lari va sarlavhalarini konsolga chiqaradi — release build'da ham. Huquqiy/shaxsiy ma'lumotlar bilan ishlaydigan ilova uchun bu logging release'da butunlay o'chirilishi tavsiya etiladi.
2. **Supabase Row Level Security (RLS) siyosati hech qayerda hujjatlashtirilmagan.** Supabase'da `anon key` mijoz tomonida ochiq bo'ladi (bu me'yor), lekin xavfsizlik butunlay backend'dagi RLS qoidalariga bog'liq bo'ladi. Fuqarolarning huquqiy murojaatlari kabi nozik ma'lumotlar bilan ishlaydigan platforma uchun bu **eng kritik xavfsizlik talabi**, va hozircha hech bir hujjatda tilga olinmagan.
3. `.env.example` namunasi mavjud emas (yuqoridagi 2-bo'limdagi topilma bilan bog'liq) — yangi dasturchi qaysi environment o'zgaruvchilari kerakligini faqat `env_config.dart` kodini o'qib bilishi mumkin.
4. Sertifikat pinning (certificate pinning) yoki boshqa transport xavfsizligi choralari hujjatlashtirilmagan — ixtiyoriy, lekin huquqiy ma'lumotlar uchun ko'rib chiqilishi mumkin.

**Baho: 14/20**

---

## 5. Kengaytirish imkoniyati

**Kuchli tomonlar:**
- Feature qo'shish konventsiyasi (`data/domain/presentation`) aniq va misol bilan tushuntirilgan.
- Marshrutlash, lokalizatsiya va DI markazlashgan — yangi feature qo'shishda "qayerga qo'shish kerak" degan savol qolmaydi.
- Riverpod tanlovi test qilish va mock qilishni osonlashtiradi (providerlarni `overrideWith` bilan almashtirish mumkin).

**Aniqlangan bo'shliqlar:**
- **Namunaviy (reference) feature yo'q.** Konventsiya faqat `docs/architecture.md`dagi matn va bitta kod bo'lagi misolida tushuntirilgan — haqiqiy `features/<nom>/` papka-fayl skeleti (bo'sh, lekin to'liq qatlamlar bilan) mavjud emas. Bu birinchi feature yozuvchisi uchun talqin qilish xavfini oshiradi.
- CI/CD konfiguratsiyasi (`flutter analyze`/`flutter test` avtomatik ishga tushirish) yo'q — hujjatlashtirilgan konventsiyalarni hech narsa avtomatik tekshirmaydi.
- `test/` papkasida na birorta namuna test bor (qasddan, biznes logika yo'qligi sababli) — lekin bu birinchi feature bilan birga "qanday test yozish kerak" savolini ham qoldiradi.
- `CHANGELOG.md` yo'q — skeleton evolyutsiyasini kuzatish uchun foydali bo'lardi.

**Baho: 15/20**

---

## Yakuniy baho

| Bo'lim | Ball | Maksimal |
|---|---:|---:|
| Arxitektura | 21 | 25 |
| Papkalar va fayl tuzilishi | 17 | 20 |
| Nomlash konventsiyalari | 12 | 15 |
| Xavfsizlik | 14 | 20 |
| Kengaytirish imkoniyati | 15 | 20 |
| **Jami** | **79** | **100** |

### Talqin

**79/100 — "Yaxshi poydevor, lekin production'ga chiqishdan oldin bir nechta muhim bo'shliq yopilishi kerak."**

Skeleton darajasida struktura, hujjatlash va nomlash sifati yuqori. Eng muhim ikki band — **(1) Supabase RLS siyosatini hujjatlashtirish/joriy etish** va **(2) `LogInterceptor`ni faqat debug rejimida yoqish** — biznes logika yozilishidan oldin, ya'ni birinchi haqiqiy feature qo'shilgunga qadar hal qilinishi tavsiya etiladi, chunki ular keyinchalik butun kod bazasiga tarqalib ketadigan naqshlarga aylanadi.

Bu audit **faqat kuzatuv** hisoblanadi — yuqoridagi hech bir topilma bo'yicha kod o'zgartirilmadi.

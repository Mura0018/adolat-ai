# SETUP.md — Adolat AI ishlab chiqish muhiti (umumiy ko'rinish)

Bu hujjat ishlab chiqish muhitining **nima**dan iboratligini, **nega** shunday tanlanganini va uni sozlash uchun **qanday** amaliy qadamlar kerakligini birlashtirib tushuntiradi — yangi qo'shilgan dasturchi yoki loyihani birinchi marta ko'rib chiqayotgan kishi uchun yuqori darajadagi mo'ljal (orientation) beradi. Amaliy, qadam-baqadam bajariladigan buyruqlar hujjat oxiridagi "Amaliy O'rnatish Qadamlari" bo'limida jamlangan.

## Purpose

- Ushbu hujjat loyihaga yangi qo'shilgan dasturchiga (yoki uni birinchi marta ko'rib chiqayotgan tomonga) quyidagi savollarga javob beradi: qanday ishlab chiqish muhiti kutilmoqda, qanday vositalar zarur, loyiha qanday tashkil etilgan, Supabase backend qanday sozlanishi kerak va buni amalda qanday bajarish mumkin.
- "Amaliy O'rnatish Qadamlari" bo'limi amaliy buyruqlar ketma-ketligini beradi (masalan `flutter pub get`); qolgan bo'limlar esa **nega** aynan shu vositalar va shu tuzilma tanlanganini tushuntiradi — ikkalasi bir-birini to'ldiradi, ziddiyatga kirmaydi.
- Texnologik tanlovlarning to'liq asoslanishi uchun: `docs/ARCHITECTURE.md` (ichki Clean Architecture va tizim darajasidagi arxitektura), `docs/DATABASE.md` va `docs/SECURITY.md` (Supabase bilan bog'liq qarorlar).

## Development Environment

- **Joriy holat:** loyiha hozircha faqat Dart-tomon skeleti sifatida tayyorlangan (`lib/`, `pubspec.yaml`, hujjatlar) — Flutter SDK o'rnatilmagan muhitda yaratilgan, shuning uchun platforma papkalari (`android/`, `ios/`, `web/`) hali mavjud emas (`README.md`, "Holat" bo'limi).
- **Maqsadli platformalar:** Android, iOS va Web — bitta Dart kod bazasidan (`README.md`, "Texnologiyalar" bo'limi).
- **Operatsion tizim cheklovi:** iOS uchun qurish va sinovdan o'tkazish faqat macOS muhitida (Xcode bilan) mumkin; Android va Web uchun Linux, macOS yoki Windows muhitlaridan foydalanish mumkin.
- **Tahrirlovchi (IDE):** aniq bitta IDE talab qilinmaydi — Flutter/Dart plaginlari o'rnatilgan istalgan muhit (masalan VS Code yoki Android Studio) mos keladi; muhim shart — Dart/Flutter tilini tushunuvchi statik tahlil va formatlash yordamchisining mavjudligi (`analysis_options.yaml`ga muvofiq tekshiruv uchun).
- **Versiya nazorati:** Git, GitHub orqali markazlashgan repozitoriy (`main` — asosiy filial; batafsil: "Git Workflow" bo'limi).
- **Backend muhiti:** lokal ishlab chiqish davomida ham haqiqiy (bulutga asoslangan) Supabase loyihasiga ulanadi — Supabase'ning to'liq lokal emulyatsiyasi MVP doirasida talab qilinmaydi (`docs/ARCHITECTURE.md`, "Deployment Architecture" bo'limi).

## Required Tools

- **Flutter SDK** — `pubspec.yaml`da belgilangan minimal versiya (`>=3.24.0`); Dart SDK Flutter bilan birga keladi (`>=3.5.0 <4.0.0`).
- **Git** — versiya nazorati va loyiha tarixini boshqarish uchun.
- **Kod generatsiyasi vositasi** — `build_runner` (`freezed`, `json_serializable` bilan birga) — loyiha immutable modellarni (`Freezed`) qo'llagani sababli zarur (`docs/ARCHITECTURE.md`, "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi).
- **Lokalizatsiya generatsiya vositasi** — Flutter tarkibidagi `gen-l10n` — `lib/localization/*.arb` fayllaridan tarjima klassini hosil qilish uchun.
- **Platforma toolchainlari:** Android uchun Android SDK (odatda Android Studio orqali o'rnatiladi); iOS uchun Xcode (faqat macOS'da); Web uchun qo'shimcha vosita talab qilinmaydi, faqat brauzer.
- **Supabase hisobi va loyihasi** — backend xizmatlariga (Auth, Database, Storage) ulanish uchun; loyiha kaliti va manzili "Environment Variables" bo'limida tavsiflangan tarzda beriladi.
- **Statik tahlil vositasi** — `flutter_lints` (dev dependency) — kod sifati konventsiyasini avtomatik tekshirish uchun (`docs/DEVELOPMENT_RULES.md`).

## Project Structure

- Loyiha **feature-first + Clean Architecture** tamoyiliga asoslangan papka tuzilmasiga ega; to'liq va batafsil jadval: `docs/folder_structure.md`.
- Yuqori darajadagi tashkillashtirish: `lib/core/` (feature'ga bog'liq bo'lmagan infratuzilma), `lib/features/` (har bir biznes imkoniyat, uch qatlamli), `lib/shared/` (feature'lar orasida umumiy kod), `lib/services/` (tashqi integratsiyalar — Supabase, Dio, Secure Storage), `lib/models/` (umumiy data modellari), `lib/widgets/` (qayta ishlatiladigan UI komponentlar), `lib/theme/`, `lib/router/`, `lib/localization/`.
- Kod bilan bog'liq bo'lmagan papkalar: `assets/` (statik resurslar), `docs/` (loyiha hujjatlari — shu hujjat shu yerda joylashadi), `test/` (avtomatik testlar, `lib/` strukturasini oynadek aks ettiradi).
- Har bir papka ichida o'ziga xos `README.md` mavjud — u yerda shu papkaning aniqroq vazifasi tushuntirilgan; yangi fayl qo'shishdan oldin shu `README.md`larni o'qish tavsiya etiladi (`docs/DEVELOPMENT_RULES.md`, "Mavjud kod va hujjatlar o'qilmasdan yangi kod yozilmaydi" tamoyili).
- Platforma papkalari (`android/`, `ios/`, `web/`) hozircha mavjud emas — ular birinchi marta loyiha ishga tushirilganda generatsiya qilinadi (amaliy qadam: "Amaliy O'rnatish Qadamlari" bo'limi).

## Environment Variables

- Loyiha maxfiy konfiguratsiya qiymatlarini `.env` fayl orqali emas, **build vaqtidagi `--dart-define` parametrlari** orqali qabul qiladi — bu yondashuv "Amaliy O'rnatish Qadamlari" bo'limida belgilangan va `lib/core/config/env_config.dart` orqali ilova ichida o'qiladi.
- Kerakli asosiy o'zgaruvchilar: Supabase loyiha manzili (URL), Supabase ochiq (`anon`) kaliti va, agar alohida API zarur bo'lsa, uning bazaviy manzili. Aniq o'zgaruvchi nomlari va ularni berish tartibi uchun: "Amaliy O'rnatish Qadamlari" bo'limi.
- **Maxfiylik talabi:** bu qiymatlar hech qachon manba kodiga qattiq yozilmaydi va versiya nazoratiga (Git) yuklanmaydi (`docs/SECURITY.md`, "Secrets Management" bo'limi; `docs/DEVELOPMENT_RULES.md`, 13-band).
- **Kalitlar ajratilishi:** klientga faqat cheklangan huquqli `anon key` beriladi; to'liq huquqli `service role` kaliti hech qachon klient tomoniga berilmaydi, faqat backend/serverless muhitda saqlanadi (`docs/SECURITY.md`, "API Security" va "Secrets Management" bo'limlari).
- **Muhitlar bo'yicha ajratish:** development, staging va production uchun alohida Supabase loyihalari va mos qiymatlar ishlatilishi tavsiya etiladi — bitta muhitning kaliti boshqasida qayta ishlatilmaydi (`docs/ARCHITECTURE.md`, "Deployment Architecture" bo'limi).

## Supabase Setup

- **Loyiha yaratish:** ishlab chiqish uchun alohida Supabase loyihasi tashkil etiladi (production loyihasidan mustaqil, "Environment Variables" bo'limidagi muhit ajratish tamoyiliga muvofiq).
- **Autentifikatsiya sozlamalari:** telefon raqami orqali ro'yxatdan o'tish uchun SMS-provayder integratsiyasi va email orqali kirish sozlanadi (`docs/SECURITY.md`, "Autentifikatsiya" bo'limi; `docs/ARCHITECTURE.md`, "Authentication Flow" bo'limi).
- **Ma'lumotlar bazasi sxemasi:** `docs/DATABASE.md`da tasvirlangan 13 jadval (`profiles`dan `audit_log`gacha) tegishli ustunlar, foreign key'lar, indekslar va CHECK cheklovlari bilan yaratiladi.
- **Row Level Security:** har bir jadval uchun RLS yoqiladi va `docs/SECURITY.md`, "Supabase RLS Security" bo'limida tavsiflangan siyosatlar (egalik asosidagi kirish, admin uchun to'liq huquq, nozik jadvallar uchun faqat service role yozuvi) joriy etiladi.
- **Storage bucket:** murojaat/nizoga biriktiriladigan fayllar uchun bucket yaratiladi, unga `docs/SECURITY.md`, "File Upload Security" bo'limidagi ruxsat etilgan tur/hajm cheklovlari va `attachments` jadvalidagi egalik mantig'iga mos kirish siyosati sozlanadi.
- **Profil avtomatik yaratilishi:** yangi `auth.users` yozuvi hosil bo'lganda mos `profiles` yozuvini avtomatik yaratuvchi backend mexanizm (trigger/service role) sozlanadi (`docs/ARCHITECTURE.md`, "Authentication Flow" bo'limi).
- **Kalitlarni loyihaga ulash:** yaratilgan Supabase loyihasining URL va `anon key` qiymatlari "Environment Variables" bo'limida tavsiflangan tarzda ilovaga uzatiladi; `service role` kaliti esa faqat backend/serverless muhitda saqlanadi va klient loyihasiga hech qachon kiritilmaydi.

## Authentication Setup

- **Telefon (SMS) provayderi:** ro'yxatdan o'tish va kirishning asosiy usuli telefon raqami bo'lgani sababli, Supabase loyihasida SMS-kod yuborish uchun mos provayder ulanadi va sinov (test) muhitida haqiqiy SMS narxi/kvotasini tejash uchun sinov raqamlari sozlanishi tavsiya etiladi (`docs/UI.md`, "Authentication Screens" bo'limi).
- **Email provayderi:** email orqali ro'yxatdan o'tish/kirish ham qo'llab-quvvatlangani uchun, tasdiqlash xatlarini yuborish uchun mos email sozlamasi ta'minlanadi.
- **Parol siyosati:** minimal uzunlik va murakkablik talabi Supabase Auth sozlamalarida belgilanadi (`docs/SECURITY.md`, "Autentifikatsiya" bo'limi).
- **Token muddati:** access va refresh token muddatlari loyiha talabiga (qisqa umrli access, uzoq umrli refresh) mos sozlanadi (`docs/SECURITY.md`, "JWT Security" bo'limi; `docs/ARCHITECTURE.md`, "Authentication Flow" bo'limi).
- **Rol avtomatik belgilanishi:** ro'yxatdan o'tish shakliga (Fuqaro/Tashkilot) qarab `profiles.role` qiymatini avtomatik to'ldiruvchi backend mexanizm sozlanishi Autentifikatsiya sozlash jarayonining ajralmas qismi hisoblanadi — foydalanuvchi rolni to'g'ridan-to'g'ri tanlab yoza olmasligi shu darajada ta'minlanadi (`docs/SECURITY.md`, "Avtorizatsiya" bo'limi).
- **Sinov (test) hisoblari:** ishlab chiqish muhitida har uchala rol (Fuqaro, Tashkilot, Admin) uchun kamida bittadan sinov hisobi yaratilishi, jamoaning har bir a'zosi rolga xos ekranlarni haqiqiy sessiya bilan sinab ko'rishini osonlashtiradi.
- **Redirect/deep-link sozlamalari:** parolni tiklash va (agar ishlatilsa) email tasdiqlash havolalari ilovaning mos ekraniga qaytarilishi uchun tegishli redirect manzillari Supabase loyihasida ro'yxatdan o'tkaziladi.

## Storage Setup

- **Bucket tashkil etilishi:** murojaat/nizoga biriktirilgan dalil fayllari uchun alohida, **ochiq bo'lmagan (private)** bucket yaratiladi — fayllarga kirish faqat autentifikatsiya va RLS/bucket policy orqali beriladi, ochiq (public) havola orqali emas (`docs/SECURITY.md`, "File Upload Security" bo'limi).
- **Kirish siyosati:** bucket darajasidagi siyosat `attachments` jadvalidagi egalik mantig'iga (muallif, yoki nizo uchun ikkala tomon, va `admin`) mos ravishda sozlanadi (`docs/ARCHITECTURE.md`, "Storage Layer" bo'limi).
- **Fayl nomlash qoidasi:** bucket ichida fayllar foydalanuvchi kiritgan asl nom bilan emas, tizim generatsiya qilgan noyob yo'l (`storage_path`) bilan saqlanishi sozlanadi — bu path traversal va nom to'qnashuvi xavfini oldini oladi.
- **Tur va hajm cheklovi:** bucket darajasida ruxsat etilgan fayl turlari (whitelist, masalan rasm va PDF formatlari) va maksimal fayl hajmi belgilanadi.
- **Offline oqim bilan bog'liqlik:** Storage bucket faqat internet mavjud bo'lganda yetkaziladigan fayllarning **yakuniy manzili** hisoblanadi — tarmoqsiz holatda fayllar qurilmada saqlanadi va Sync Engine internet tiklangach ularni shu bucket'ga yuklaydi (`docs/ARCHITECTURE.md`, "Offline-First Architecture" va "Sync Engine" bo'limlari); Storage Setup jarayonining o'zi bu offline mexanizmni emas, faqat uning yakuniy nishonini (target) tayyorlaydi.
- **Muhitlar bo'yicha ajratish:** development va production bucket'lari alohida Supabase loyihalarida joylashgani sababli tabiiy ravishda ajratilgan — bir muhitdagi sinov fayllari boshqasiga aralashmaydi.

## Development Workflow

- **Ishni boshlashdan oldin:** mavjud kod va tegishli hujjatlar (loyihaviy `docs/*.md`, papka `README.md`lari) o'qilmasdan yangi kod yozilmaydi (`docs/DEVELOPMENT_RULES.md`, 5-band) — bu, ayniqsa, mavjud feature'ga o'xshash yangi feature qo'shishda, konventsiyadan chetga chiqishning oldini oladi.
- **Kundalik tsikl:** kod bazasining so'nggi holatini olish, bog'liqliklarni yangilash, agar Freezed/JSON modellariga o'zgartirish kiritilgan bo'lsa kod generatsiyasini qayta ishga tushirish, so'ng ilovani mos environment o'zgaruvchilari bilan ishga tushirish (aniq buyruqlar: "Amaliy O'rnatish Qadamlari" bo'limi).
- **Statik tahlil va formatlash:** har qanday o'zgarish commit qilinishidan oldin loyihaning lint/statik tahlil qoidalariga (`analysis_options.yaml`) mos ekanligi tekshiriladi — bu Clean Architecture qatlamlanishi va nomlash konventsiyalarining (`docs/ARCHITECTURE.md`, "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi) buzilmasligini avtomatik nazorat qiladi.
- **Offline-first funksionallikni sinash:** murojaat/nizo yoki fayl bilan bog'liq har qanday o'zgarish, tarmoq o'chirilgan holatda ham (masalan qurilma "parvoz rejimi"da) qo'lda sinovdan o'tkaziladi — bu MVP'ning majburiy talabi bo'lgani sababli (`docs/ARCHITECTURE.md`, "Offline-First Architecture" bo'limi), oddiy onlayn stsenariy yetarli emas.
- **Feature qo'shish konventsiyasi:** har bir yangi biznes imkoniyat `docs/ARCHITECTURE.md`da (Ichki Kod Arxitekturasi bo'limida) tasvirlangan `data/domain/presentation` uch qatlamiga muvofiq tuziladi; mavjud feature (masalan autentifikatsiya) namunaviy (reference) sifatida ko'rib chiqiladi (`docs/ROADMAP.md`, Bosqich 1).
- **Hujjatlashtirish:** API yoki ma'lumotlar bazasiga tegishli har qanday o'zgarish tegishli hujjatda (`docs/DATABASE.md`, `docs/SECURITY.md` va h.k.) aks ettiriladi (`docs/DEVELOPMENT_RULES.md`, 9-band) — kod va hujjat bir vaqtda yangilanadi, hujjat "keyinroq" qoldirilmaydi.

## Git Workflow

- **Asosiy filial:** `main` — loyihaning barqaror holatini aks ettiradi; unga bevosita, tekshirilmagan yirik o'zgarish kiritilmaydi.
- **Har bir muhim o'zgarish — alohida commit:** bitta commit bitta mantiqiy, tushunarli o'zgarishni ifodalaydi; bir nechta bog'liq bo'lmagan o'zgarish bitta commitga yig'ilmaydi (`docs/DEVELOPMENT_RULES.md`, 10-band).
- **Commit oldidan tekshiruv:** har bir commitdan oldin kod (va, agar tegishli bo'lsa, hujjat) ko'rib chiqiladi — statik tahlil xatoliklari yoki noaniq o'zgarishlar bilan commit qilinmaydi (`docs/DEVELOPMENT_RULES.md`, 21-band).
- **Commit xabari:** o'zgarishning **nima** emas, **nega** qilingani asosiy e'tiborda bo'ladigan, qisqa va aniq xabar yoziladi — bu keyinchalik loyiha tarixini o'qishni osonlashtiradi.
- **Yirik o'zgarish uchun alohida filial (branch):** feature yoki tuzatish o'z filialida ishlab chiqiladi va ko'rib chiqilgach (review) `main`ga birlashtiriladi — bu jamoa kattalashganda parallel ishlashni ziddiyatsiz qiladi.
- **Reliz oldidan audit darvozasi:** `main`dagi o'zgarishlar reliz sifatida chiqarilishidan oldin Security/Performance/UX auditlaridan o'tishi shart; audit balli 95dan past yoki critical xavfsizlik kamchiligi bo'lsa, reliz to'xtatiladi (`docs/DEVELOPMENT_RULES.md`, 22–24-bandlar; `docs/ROADMAP.md`, "Release Criteria" bo'limi).
- **Maxfiy ma'lumot bilan bog'liq ehtiyotkorlik:** commit qilishdan oldin o'zgargan fayllar ro'yxati ko'rib chiqiladi — `.env` yoki boshqa maxfiy qiymat tasodifan qo'shilib qolmasligi tasdiqlanadi (`docs/SECURITY.md`, "Secrets Management" bo'limi).

## Configuration Management

- **Markazlashgan konfiguratsiya nuqtasi:** barcha muhitga xos qiymatlar (Supabase URL, kalitlar, API manzili) `lib/core/config/`dagi yagona konfiguratsiya klassi orqali o'qiladi — ilova kodining boshqa qismlari muhit qiymatlarini to'g'ridan-to'g'ri emas, shu markazlashgan nuqta orqali oladi.
- **Qiymatlarning kelib chiqishi:** haqiqiy qiymatlar kodga yozilmaydi, build vaqtida tashqaridan (`--dart-define` orqali) beriladi — aniq mexanizm "Environment Variables" bo'limida tavsiflangan, bu yerda takrorlanmaydi.
- **Muhitlar orasidagi izchillik:** development, staging va production muhitlari bir xil konfiguratsiya **shakliga** (qaysi o'zgaruvchilar kerakligiga) ega bo'ladi, faqat qiymatlari farq qiladi — bu farqlarni kutilmagan xatti-harakatlarga olib kelmasligini ta'minlaydi.
- **Konfiguratsiya o'zgarishini hujjatlashtirish:** yangi environment o'zgaruvchisi qo'shilsa yoki mavjudi o'zgartirilsa, bu o'zgarish ushbu hujjatning "Amaliy O'rnatish Qadamlari" bo'limida (amaliy qadam sifatida) va zarur bo'lsa boshqa tegishli joyda aks ettiriladi — kod bazasidagi konfiguratsiya talabi va hujjat doimo sinxron saqlanadi.
- **Qattiq yozilgan (hardcoded) qiymatlarga yo'l qo'yilmaydi:** muhitga bog'liq bo'lgan hech qanday qiymat (masalan test uchun vaqtinchalik URL) kodda doimiy qoldirilmaydi — bu keyinchalik muhitlar orasida tasodifiy chalkashlikning oldini oladi.
- **Maxfiy va nomaxfiy konfiguratsiya farqi:** nomaxfiy sozlamalar (masalan ilova nomi, versiya) kodda ochiq saqlanishi mumkin; maxfiy qiymatlar esa har doim "Environment Variables" bo'limidagi qoidaga bo'ysunadi — ikkalasi bir xil mexanizmda aralashtirilmaydi.

## Testing Environment

- **Test tuzilmasi:** `test/` papkasi `lib/` strukturasini oynadek aks ettiradi (`docs/folder_structure.md`) — har bir feature'ning `data`/`domain`/`presentation` qatlamlari o'ziga mos test papkasiga ega bo'ladi.
- **Qatlamlarga mos test turlari:** `domain/` sof Dart bo'lgani sababli tashqi bog'liqliksiz unit test bilan qamrab olinadi; `data/` qatlami datasource'larni soxtalashtirib (mock) sinovdan o'tkaziladi; `presentation/` esa widget testlari orqali tekshiriladi (`docs/ARCHITECTURE.md`, "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi).
- **Holat boshqaruvini sinash:** Riverpod providerlari test muhitida `overrideWith` orqali almashtiriladi — bu haqiqiy Supabase chaqiruvisiz ham biznes mantiqni tekshirish imkonini beradi.
- **Test uchun Supabase muhiti:** avtomatik testlar imkon qadar mock/soxtalashtirilgan datasource orqali ishlaydi; haqiqiy Supabase loyihasiga ulanishni talab qiladigan qo'lda (manual) sinovlar uchun "Authentication Setup" bo'limida tavsiflangan sinov hisoblaridan foydalaniladi.
- **Offline-first stsenariylarini sinash:** murojaat/nizo va fayl bilan bog'liq testlar nafaqat onlayn, balki tarmoqsiz holatni ham qamrab olishi kerak — bu avtomatik test bilan to'liq qamrab bo'lmasa, kamida qo'lda sinov sifatida "Development Workflow" bo'limidagi talabga muvofiq bajariladi.
- **Joriy cheklov:** loyiha hozircha skeleton bosqichida bo'lgani va avtomatik CI quvur liniyasi (pipeline) mavjud bo'lmagani sababli (`PROJECT_AUDIT.md`, "Kengaytirish imkoniyati" bo'limi), testlar hozircha faqat qo'lda ishga tushiriladi — bu holat birinchi feature'lar qo'shilishi bilan qayta ko'rib chiqilishi kerak.

## Build & Release Preparation

- **Versiyalash:** ilova versiyasi `pubspec.yaml`dagi `version` maydonida (masalan `0.1.0+1`) yuritiladi; har bir reliz oldidan bu qiymat mos ravishda oshiriladi.
- **Muhitga xos konfiguratsiya:** build vaqtida to'g'ri muhitga (development/staging/production) mos environment qiymatlari uzatilishi shart — "Environment Variables" va "Configuration Management" bo'limlaridagi qoidaga muvofiq, xato muhit qiymati bilan reliz yig'ilmasligi tekshiriladi.
- **Platformaga xos imzolash:** Android uchun imzolash kaliti (keystore), iOS uchun tegishli sertifikat va profil talab qilinadi — bu materiallar loyiha kod bazasida emas, xavfsiz alohida joyda saqlanadi (`docs/SECURITY.md`, "Secrets Management" bo'limidagi tamoyilga muvofiq).
- **Uch platforma uchun tayyorgarlik:** Android (APK/AAB), iOS (IPA) va Web (statik build) — har biri alohida tayyorgarlik va tarqatish kanaliga ega (`docs/ARCHITECTURE.md`, "Deployment Architecture" bo'limi).
- **Reliz oldidan majburiy auditlar:** Security, Performance va UX auditlari o'tkazilib, natija 95 balldan past bo'lmasligi va critical xavfsizlik kamchiligi mavjud emasligi tasdiqlanadi (`docs/DEVELOPMENT_RULES.md`, 22–24-bandlar; `docs/ROADMAP.md`, "Release Criteria" bo'limi) — bu tekshiruv shu bo'limda takrorlanmaydi, faqat build jarayonining shart-sharti sifatida eslatiladi.
- **Reliz oldidan yakuniy ro'yxat:** amaliy tayyorgarlik holatini tasdiqlash uchun ushbu hujjatning "Checklist" bo'limidan foydalaniladi.

## Troubleshooting

- **Platforma papkalari (`android/`, `ios/`, `web/`) topilmayapti:** bu kutilgan holat — loyiha skeleton sifatida ular yo'q holda tayyorlangan; ular birinchi ishga tushirishda generatsiya qilinishi kerak ("Development Environment" bo'limi; amaliy qadam: "Amaliy O'rnatish Qadamlari" bo'limi).
- **Generatsiya qilingan fayllar (`*.freezed.dart`, `*.g.dart`) eskirgan yoki topilmayapti:** bu fayllar versiya nazoratida saqlanmaydi (`docs/ARCHITECTURE.md`, "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi) — model o'zgarganda kod generatsiya vositasi qayta ishga tushirilishi kerak ("Required Tools" bo'limi).
- **Lokalizatsiya klassi (`AppLocalizations`) topilmayapti:** `.arb` fayllaridan generatsiya qilinmagan bo'lishi mumkin — lokalizatsiya generatsiya vositasi ishga tushirilishi kerak ("Required Tools" bo'limi).
- **Ilova ishga tushganda Supabase'ga ulanolmayapti:** environment o'zgaruvchilari (URL, `anon key`) build vaqtida berilmagan yoki noto'g'ri bo'lishi mumkin — "Environment Variables" bo'limidagi talablar qayta tekshiriladi.
- **"Ruxsat yo'q" (RLS reject) xatoligi kutilmaganda chiqmoqda:** bu ko'pincha xato emas, balki RLS siyosatining to'g'ri ishlayotganining belgisi — foydalanuvchi rolining va egalik shartining kutilganga mosligini "Supabase Setup" va `docs/SECURITY.md`, "Supabase RLS Security" bo'limi asosida tekshirish kerak.
- **Ilova internetsiz "ishlamayapti" deb ko'rinadi:** bu holat avval xatolik emas, arxitektura talabining buzilishi sifatida ko'rib chiqilishi kerak — `docs/ARCHITECTURE.md`, "Offline-First Architecture" bo'limiga muvofiq ilova bunday holatda ham ishlashi shart; agar ishlamasa, bu holat kamchilik (bug) sifatida qayd etiladi, "kutilgan xatti-harakat" sifatida emas.
- **Push xabarnoma yetib kelmayapti:** bu ilovaning noto'g'ri ishlashi degani emas — `docs/ARCHITECTURE.md`, "Push Notifications" bo'limiga muvofiq, push faqat "eng yaxshi urinish" kanali; ilova ichidagi xabarnomalar ro'yxati har doim to'g'ri holatni ko'rsatishi tekshiriladi.

## Checklist

Yangi qo'shilgan dasturchi yoki ishlab chiqish muhitini birinchi marta sozlayotgan kishi uchun tayyorgarlik ro'yxati:

- [ ] Flutter SDK "Required Tools" bo'limidagi minimal versiyaga mos o'rnatilgan.
- [ ] Loyiha hujjatlari (`README.md`, `docs/ARCHITECTURE.md`, `docs/folder_structure.md`, `docs/DEVELOPMENT_RULES.md`) o'qib chiqilgan.
- [ ] Platforma papkalari (`android/`/`ios`/`web`) generatsiya qilingan ("Development Environment" bo'limi).
- [ ] Bog'liqliklar o'rnatilgan va kod generatsiyasi (Freezed/JSON) muvaffaqiyatli ishga tushirilgan.
- [ ] Lokalizatsiya klassi generatsiya qilingan.
- [ ] Ishlab chiqish uchun Supabase loyihasiga kirish huquqi va "Environment Variables" bo'limida tavsiflangan qiymatlar qo'lda mavjud.
- [ ] Supabase loyihasida "Supabase Setup" bo'limidagi barcha qadamlar (sxema, RLS, Storage bucket, autentifikatsiya) bajarilgan.
- [ ] Har uchala rol (Fuqaro, Tashkilot, Admin) uchun sinov hisoblari mavjud ("Authentication Setup" bo'limi).
- [ ] Statik tahlil/lint vositasi xatoliksiz o'tadi.
- [ ] Git repozitoriysiga kirish huquqi va "Git Workflow" bo'limidagi konventsiyalar bilan tanishlik tasdiqlangan.
- [ ] Offline-first talabining nima ekanligi (`docs/ARCHITECTURE.md`, "Offline-First Architecture" bo'limi) tushunilgan — bu MVP'ning muzokara qilinmaydigan talabi.
- [ ] `docs/DEVELOPMENT_RULES.md`dagi jarayon qoidalari (ayniqsa "No Dead End Rule" va commit/audit talablari) bilan tanishilgan.

## Amaliy O'rnatish Qadamlari

Bu bo'lim — yuqoridagi bo'limlarda tushuntirilgan qarorlarning amaliy, qadam-baqadam bajariladigan buyruqlar ketma-ketligi. Loyiha hozircha faqat Dart-tomon skeleti sifatida tayyorlangan (`lib/`, `pubspec.yaml`, hujjatlar) — Flutter SDK o'rnatilmagan muhitda yaratilgan. Loyihani birinchi marta ishga tushirishdan oldin quyidagi qadamlarni bajaring.

### 1. Flutter SDK o'rnatish

Agar hali o'rnatilmagan bo'lsa: https://docs.flutter.dev/get-started/install

Tekshirish:

```bash
flutter --version
flutter doctor
```

### 2. Platforma papkalarini generatsiya qilish (android/ios/web)

Bu skeletda `android/`, `ios/`, `web/` papkalari **yo'q** — ular qo'lda soxta yaratilmagan (bu xato va ishonchsiz bo'lardi). Loyiha ildizida quyidagini ishga tushiring:

```bash
flutter create --platforms=android,ios,web --org com.adolatai .
```

Bu buyruq mavjud fayllarni (README.md, pubspec.yaml, lib/) qayta yozib yubormaydi — faqat yetishmayotgan platforma papkalarini qo'shadi.

### 3. Paketlarni o'rnatish

```bash
flutter pub get
```

### 4. Kod generatsiyasi (Freezed / json_serializable)

Hozircha `lib/` ichida `@freezed` bilan yozilgan haqiqiy model yo'q (skeletda biznes logika yo'qligi sababli), lekin birinchi feature qo'shilganda:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Lokalizatsiya generatsiyasi

```bash
flutter gen-l10n
```

Bu `lib/localization/*.arb` fayllaridan `AppLocalizations` klassini generatsiya qiladi. Generatsiyadan so'ng `lib/app.dart`dagi `localizationsDelegates` ro'yxatiga `AppLocalizations.delegate` qo'shing (fayldagi izohga qarang).

### 6. Environment o'zgaruvchilarini berish

Supabase va API kalitlari `--dart-define` orqali beriladi (`.env` fayli commit qilinmaydi):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxxx \
  --dart-define=API_BASE_URL=https://api.adolat.ai
```

### 7. Ishga tushirish

```bash
flutter run
```

### Qisqacha buyruqlar ketma-ketligi

```bash
flutter create --platforms=android,ios,web --org com.adolatai .
flutter pub get
flutter gen-l10n
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

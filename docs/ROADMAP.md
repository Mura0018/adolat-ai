# ROADMAP.md — Adolat AI rivojlanish yo'l xaritasi

Bu hujjat **faqat rejalashtirish hujjati** — kod yo'q. Maqsad: loyihaning uzoq muddatli maqsadini, MVP chegarasini va MVP'ga yetish uchun bosqichma-bosqich rivojlanish rejasini belgilash. Texnik tafsilotlar uchun: `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/SECURITY.md`, `docs/UI.md`; jarayon qoidalari uchun: `docs/DEVELOPMENT_RULES.md`; joriy holat baholovi uchun: `PROJECT_AUDIT.md`.

## Project Vision

Adolat AI — O'zbekiston fuqarolari va tashkilotlariga huquqiy yordamni **oddiy, tezkor va tarafsiz** qilish orqali adolatga kirish imkoniyatini kengaytirishga qaratilgan platforma.

Uzoq muddatli maqsad — har bir fuqaro, murakkab yuridik atamalarni bilmasa ham yoki yurist yollashga imkoniyati bo'lmasa ham:

- o'z huquqini tushunishi,
- davlat organiga to'g'ri va tuzilgan murojaat yubora olishi,
- boshqa tomon bilan nizoni tarafsiz, faktlarga asoslangan tahlil orqali hal qilish yo'lini topa olishi mumkin bo'lishi.

Bu maqsadga sun'iy intellektni **inson yuristining o'rnini bosuvchi emas, balki har kimga tenglashtirilgan boshlang'ich huquqiy yordam vositasi** sifatida ishlatish orqali erishiladi — AI hech qachon bir tomon foydasiga xolislikni buzmaydi va faqat qonun hamda taqdim etilgan faktlarga tayanadi (`docs/DEVELOPMENT_RULES.md`, 15–16-bandlar).

Platforma ishonch, shaffoflik va foydalanuvchini hech qachon yechimsiz holatda qoldirmaslik tamoyillari asosida quriladi (`docs/UI.md`, "Design Principles" bo'limi) — bu nafaqat UX qoidasi, balki mahsulotning yuridik-ijtimoiy vazifasining o'zagi.

## MVP Scope

MVP quyidagi tasdiqlangan ko'lam asosida aniqlangan (`docs/DATABASE.md`, "MVP doirasi bo'yicha qabul qilingan qarorlar" bo'limi):

**MVP ichida:**

- **Ikkita asosiy oqim:** (a) davlat organiga murojaat yuborish, (b) ikki tomon o'rtasidagi nizoni AI orqali tarafsiz tahlil qilish.
- **Uchta foydalanuvchi roli:** Fuqaro (`citizen`), Tashkilot (`organization`), Admin (`admin`) — `docs/SECURITY.md`, "Avtorizatsiya" bo'limi.
- **Faqat AI ishtirok etadi** — yurist/operator roli va tayinlash (assignment) mexanizmi hozircha yo'q.
- **Fayl/hujjat biriktirish** — dalil va hujjatlar uchun.
- **Offline-first arxitektura** — majburiy, ixtiyoriy emas: ilova internet bo'lmasa ham to'liq ishlaydi, murojaat/nizo offline yaratiladi, fayllar vaqtincha lokal saqlanadi, AI vazifalari navbatga qo'yiladi, internet qaytganda avtomatik sinxronlanadi (`docs/ARCHITECTURE.md`, "Offline-First Architecture" bo'limi).
- **Push xabarnomalar** — holat o'zgarishlari haqida real vaqtda xabardor qilish (`docs/ARCHITECTURE.md`, "Push Notifications" bo'limi).
- **Audit va xavfsizlik** — RLS, service role chegarasi, o'zgarmas audit jurnali (`docs/SECURITY.md`).

**MVP tashqarisida (ataylab qoldirilgan):**

- Yurist/operator roli va murojaat/nizoni tayinlash (assignment) jadvali.
- Ko'p tomonli nizolar (faqat ikki tomonli nizo qo'llab-quvvatlanadi).
- Davlat organlari bilan avtomatik integratsiya (rasmiy javob hozircha admin tomonidan qo'lda kiritiladi).
- SMS/email kabi qo'shimcha xabarnoma kanallari (faqat push).
- Qonun moddalari versiyalash tarixi.

Yuqoridagi chegaralar `docs/DATABASE.md`da batafsil asoslangan; kelgusi g'oyalar `docs/IDEA_PARKING.md`ga yoziladi (`docs/DEVELOPMENT_RULES.md`, 8-band).

## Development Phases

MVP'ga yetish quyidagi ketma-ket bosqichlarga bo'lingan. Har bir bosqich oldingisining ustiga quriladi va Sprint yakunida audit talabidan o'tishi shart (`docs/DEVELOPMENT_RULES.md`, 20–25-bandlar).

- **Bosqich 0 — Poydevor va hujjatlash (yakunlangan):** loyiha ko'rinishi (vision), papka strukturasi, Clean Architecture konventsiyasi, ma'lumotlar bazasi dizayni, xavfsizlik arxitekturasi, tizim arxitekturasi va UI dizayni hujjatlashtirildi (`README.md`, `docs/DATABASE.md`, `docs/SECURITY.md`, `docs/ARCHITECTURE.md`, `docs/UI.md`). Dart skeleti (`lib/`, `pubspec.yaml`) tayyorlangan, lekin biznes logika hali yozilmagan (`PROJECT_AUDIT.md`).
- **Bosqich 1 — Poydevor infratuzilmasi va Autentifikatsiya:** haqiqiy Supabase loyihasi, RLS siyosatlarining dastlabki qo'llanilishi va to'liq autentifikatsiya oqimi (batafsil quyida).
- **Bosqich 2 — Murojaat (Appeals) oqimi:** murojaat yaratish, tahrirlash, yuborish, holatini kuzatish va rasmiy javobni ko'rish (admin tomonidan kiritilgan).
- **Bosqich 3 — Nizo (Disputes) va AI tahlili:** ikki tomonli nizo yaratish, tomonlar faktlarini taqdim etishi, AI Service integratsiyasi va tarafsiz tahlil natijasini ko'rsatish.
- **Bosqich 4 — Offline-First va Sinxronizatsiya:** Local Storage, Sync Engine, Conflict Resolution va Network State Handling mexanizmlarining to'liq implementatsiyasi (`docs/ARCHITECTURE.md`dagi tegishli bo'limlarga muvofiq) — murojaat/nizo va fayl oqimlariga bog'lab.
- **Bosqich 5 — Admin paneli va xabarnomalar:** admin uchun boshqaruv interfeysi (ma'lumotnomalar, holat boshqaruvi, audit jurnali ko'rish) va push xabarnoma tizimining to'liq ishga tushirilishi.
- **Bosqich 6 — Mustahkamlash, audit va reliz tayyorgarligi:** Security/Performance/UX auditlari, aniqlangan kamchiliklarni yopish (`docs/ACTION_PLAN.md` orqali), reliz oldidan yakuniy tekshiruv (`docs/SECURITY.md`, "Security Checklist" bo'limi). **Old shart:** bu bosqich Bosqich 1, 3, 4 va 5 funksional jihatdan yakunlangandan keyingina boshlanadi — u "oxirgi jilolash" bosqichi, "keyingi ish bloki" degani emas.

Bosqichlar orasidagi chegara qat'iy emas — keyingi bosqich boshlanishi joriy bosqichning audit talabidan o'tishiga bog'liq (`docs/DEVELOPMENT_RULES.md`, 23-band).

> **Muhim atama aniqligi:** loyiha muhokamalarida (masalan Claude Code bilan suhbatda) "Phase 6" yoki "Bosqich 6" so'zi ba'zan norasmiy ma'noda — "keyingi ish bloki" degan ma'noda — ishlatilishi mumkin. Bu hujjatdagi **Bosqich 6** esa qat'iy, tor ma'noga ega: yuqoridagi olti bosqichning oxirgisi, Bosqich 1/3/4/5 funksional yakunlangandan keyingina boshlanadigan reliz-tayyorgarlik bosqichi. Har qanday norasmiy "Phase 6" murojaati ushbu rasmiy Bosqich 6 bilan avtomatik tenglashtirilmasligi kerak — agar Bosqich 1/3/4/5 hali yakunlanmagan bo'lsa, "Phase 6"ni boshlash so'ralganda, bu chalkashlikni aniqlashtirish talab qilinadi.

## Phase 1 Goals

Bosqich 1 maqsadi — ilovaning "hech narsa ishlamaydi" holatidan "foydalanuvchi haqiqatan ham tizimga kira oladi va o'z rolida asosiy ekranni ko'radi" holatiga o'tish, shu bilan birga `PROJECT_AUDIT.md`da aniqlangan poydevor darajasidagi bo'shliqlarni yopish.

- **Haqiqiy Supabase loyihasini o'rnatish** va `profiles`/`organization_profiles` jadvallari uchun `docs/DATABASE.md`da belgilangan sxema va `docs/SECURITY.md`da belgilangan RLS siyosatlarini amalda joriy etish — bu `PROJECT_AUDIT.md`da eng kritik topilma sifatida belgilangan ("Xavfsizlik" bo'limi, 2-band).
- **To'liq autentifikatsiya oqimini amalga oshirish** — `docs/UI.md`, "Authentication Screens" va `docs/ARCHITECTURE.md`, "Authentication Flow" bo'limlariga muvofiq: ro'yxatdan o'tish (Fuqaro/Tashkilot), SMS tasdiqlash, kirish, parolni tiklash, chiqish.
- **Rolga asoslangan navigatsiya skeletini o'rnatish** — `docs/UI.md`, "Navigation Structure" bo'limidagi ikkita navigatsiya tuzilmasi (Fuqaro/Tashkilot uchun birgalikda, Admin uchun alohida) bo'sh/skeleton ekranlar bilan bo'lsa-da, auth guard orqali ishlaydigan holga keltirish.
- **Arxitektura poydevoridagi audit bo'shliqlarini yopish:** `core/error/`da haqiqiy `Failure` bazaviy klassini yaratish, markazlashgan xatolik qayta ishlash zanjirini o'rnatish (`docs/ARCHITECTURE.md`, "Error Handling" bo'limi), `dio_client.dart`dagi loglashni faqat debug rejimida faollashtirish (`PROJECT_AUDIT.md`, "Xavfsizlik" bo'limi, 1-band).
- **Namunaviy (reference) feature yaratish:** autentifikatsiya feature'ining o'zi kelgusi barcha feature'lar uchun `data/domain/presentation` naqshining jonli namunasiga aylanishi (`PROJECT_AUDIT.md`, "Kengaytirish imkoniyati" bo'limi, 1-band).
- **Xavfsiz mahalliy saqlashni ishga tushirish:** token va sessiya ma'lumotlarini `Flutter Secure Storage` orqali saqlash va ilova qayta ochilganda sessiyani tiklash (`docs/UI.md`, "App Entry Flow" bo'limi).

## Phase 1 Deliverables

- Ishlaydigan Supabase loyihasi: `auth.users`, `profiles`, `organization_profiles` jadvallari, ular ustida faol RLS siyosatlari va `profiles` yozuvini avtomatik yaratuvchi trigger/service-role mexanizmi.
- To'liq ishlaydigan ekranlar to'plami: ro'yxatdan o'tish (Fuqaro va Tashkilot shakllari), SMS tasdiqlash, kirish, parolni tiklash, chiqish tasdiqlashi — barchasi `docs/UI.md`dagi tavsifga mos.
- Splash/App Entry Flow implementatsiyasi: mavjud sessiyani aniqlash va foydalanuvchini to'g'ri rolga mos ekranga yo'naltirish.
- GoRouter darajasidagi auth guard: himoyalangan marshrutlarga sessiyasiz kirishning oldini olish.
- Fuqaro/Tashkilot va Admin uchun bo'sh (placeholder), lekin navigatsiya jihatidan to'liq ishlaydigan asosiy ekranlar skeleti (`docs/UI.md`, "Navigation Structure" bo'limidagi bo'limlar bo'yicha).
- `core/error/`dagi `Failure` sealed union implementatsiyasi va kamida autentifikatsiya feature'i orqali sinovdan o'tgan `Exception → Failure` zanjiri.
- Tuzatilgan `dio_client.dart` — `LogInterceptor` faqat `kDebugMode`da faol.
- Yangilangan `docs/SETUP.md` (agar Supabase loyihasini sozlash bo'yicha yangi amaliy qadamlar paydo bo'lsa) va yangilangan `PROJECT_AUDIT.md` qayta baholovi — Bosqich 1 yakunida "Xavfsizlik" va "Kengaytirish imkoniyati" bo'limlaridagi tegishli topilmalarning yopilganini ko'rsatuvchi.

## Joriy amalga oshirish holati (2026-07-28 holatiga)

Bu bo'lim yuqoridagi rejalashtirilgan bosqich ketma-ketligi bilan **haqiqiy** qurilish tartibi o'rtasidagi farqni hujjatlashtiradi (`docs/DEVELOPMENT_RULES.md`, "Hujjat-kod muvofiqligi" talabi). Bu farq atayin emas — u loyihaning haqiqiy rivojlanish tartibi natijasida yuzaga keldi va Bosqich 6'dan oldin yopilishi kerak bo'lgan bilinga ma'lum bo'shliq sifatida qayd etiladi.

**Qurilgan (rejalashtirilgan tartibdan farqli ketma-ketlikda):**

- Bosqich 1'ning **backend qismi**: haqiqiy Supabase sxemasi, RLS siyosatlari (endi `is_admin()`/`owns_appeal()`/`is_dispute_party()`/`can_access_case()` orqali markazlashtirilgan — `docs/DATABASE.md`, "Umumiy konventsiyalar" bo'limi), Storage foundation va `profiles`ni avtomatik yaratuvchi autentifikatsiya trigger'i — to'liq bajarilgan va commit qilingan.
- Bosqich 2 (Appeals) va Bosqich 3 (Disputes)ning **Flutter UI qismi** — murojaat/nizo yaratish, tahrirlash, yuborish, fayl biriktirish va AI tahlil natijasini ko'rish ekranlari — Clean Architecture uch qatlami (`data`/`domain`/`presentation`) bilan qurilgan, lekin Bosqich 1'ning Flutter UI qismidan (pastda) **oldin**.

**Qurilmagan — Bosqich 1'ning Flutter UI qismi (bilinga bo'shliq):**

- Ro'yxatdan o'tish, SMS tasdiqlash, kirish, parolni tiklash ekranlari qurilmagan.
- Splash/App Entry Flow (mavjud sessiyani aniqlash) va GoRouter darajasidagi auth guard qurilmagan.
- Rolga asoslangan navigatsiya skeleti (Fuqaro/Tashkilot/Admin uchun asosiy ekranlar) qurilmagan.
- **Amaliy natija:** hozirgi holatda foydalanuvchi ilovaga kira olmaydi — qurilgan `appeals`/`disputes` ekranlariga hech qanday auth'dan o'tgan holda yetib bo'lmaydi (kirish nuqtasi yo'q). Bu topilma "Pre-Phase 6 Hardening Sprint" doirasida **ataylab tuzatilmadi**, chunki bu yangi funksiya qo'shishni talab qiladi (sprint ko'lami faqat mavjud poydevorni mustahkamlash bilan cheklangan) — Bosqich 6 boshlanishidan oldin yopilishi shart bo'lgan bilinga qoldirilgan ish sifatida shu yerda qayd etiladi.
- Offline-First (Bosqich 4) qurilmagan — bu rejalashtirilgan tartibga mos, muddatidan oldin emas.

**Xulosa:** MVP Scope va Release Criteria'dagi talablar o'zgarmagan; faqat qurilish TARTIBI rejalashtirilganidan farq qildi. Keyingi ish — avval Bosqich 1'ning qolgan Flutter UI qismini (yuqoridagi bo'shliqlar) yopish, so'ngra Bosqich 3'ning AI Service qismini, Bosqich 4'ni va Bosqich 5'ni yakunlash, va faqat shundan keyin rasmiy Bosqich 6 (yuqoridagi "Development Phases" bo'limidagi old shartga muvofiq) boshlanadi. Joriy sanada ("2026-07-28 holatiga") loyiha hali Bosqich 6'ni boshlash uchun tayyor emas.

## Phase 2

Bosqich 2 maqsadi — Bosqich 1'da o'rnatilgan autentifikatsiya poydevori ustiga birinchi haqiqiy biznes oqimini, murojaat (`appeals`) funksiyasini, to'liq holda qurish.

**Maqsadlar:**

- `appeals`, `legal_categories`, `government_bodies` jadvallari uchun sxema va RLS siyosatlarini joriy etish (`docs/DATABASE.md`, 3–5-jadvallar; `docs/SECURITY.md`, "Supabase RLS Security" bo'limi).
- Murojaat holat ketma-ketligini (`draft` → `submitted` → `in_review` → `answered`/`rejected` → `closed`) to'liq amalga oshirish (`docs/ARCHITECTURE.md`, "Case Lifecycle" bo'limi).
- Murojaat yaratish, tahrirlash, huquqiy kategoriya va davlat organini tanlash, fayl biriktirish ekranlarini qurish.
- Admin uchun murojaatlarni ko'rib chiqish, holatini yangilash va rasmiy javob kiritish imkoniyatini qo'shish.
- `case_status_history` orqali har bir holat o'zgarishini o'zgarmas audit yozuvi sifatida qayd etish.
- Murojaat holati o'zgarganda `notifications` yozuvini hosil qilish (push yetkazish Bosqich 5'da to'liq ishga tushiriladi, lekin yozuv darajasi shu bosqichda tayyor bo'ladi).

**Yetkazib beriladigan natijalar (deliverables):**

- To'liq ishlaydigan murojaat yaratish/tahrirlash/yuborish oqimi (Fuqaro va Tashkilot uchun bir xil).
- Fayl biriktirish (`attachments`) — Storage Layer bilan integratsiya, ruxsat etilgan tur/hajm cheklovlari bilan (`docs/SECURITY.md`, "File Upload Security" bo'limi).
- Admin uchun murojaatlar ro'yxati, filtrlash va holat/rasmiy javob boshqaruvi ekrani.
- Murojaatga oid barcha RLS siyosatlari va DB darajasidagi CHECK cheklovlari (`docs/DATABASE.md`dagi "mutually exclusive FK" naqshi) amalda tekshirilgan.
- Bosqich 2 doirasida yaratilgan `appeals` feature'i, Bosqich 1'dagi autentifikatsiya naqshiga to'liq mos (Clean Architecture uch qatlami, `Failure` orqali xatolik boshqaruvi).

## Phase 3

Bosqich 3 maqsadi — platformaning ikkinchi asosiy oqimi, ikki tomonli nizo (`disputes`) va AI Service integratsiyasini qurish — bu MVP'ning eng murakkab va mahsulotning o'ziga xos qiymatini tashkil etuvchi qismi.

**Maqsadlar:**

- `disputes`, `laws`, `ai_analyses`, `ai_analysis_law_references` jadvallari uchun sxema va RLS siyosatlarini joriy etish (`docs/DATABASE.md`, 6, 8, 9, 10-jadvallar).
- Nizo holat ketma-ketligini (`open` → `ai_analyzing` → `ai_analyzed` → `resolved`/`closed`) amalga oshirish.
- Nizo yaratish (initiator), qarshi tomonni belgilash (ro'yxatdan o'tgan yoki o'tmagan) va ikkala tomonning faktlarini (`description`/`respondent_statement`) kiritish oqimini qurish.
- AI Service bilan backend/service-role chegarasi orqali integratsiya — murojaat/nizo tegishli holatga o'tganda tahlil so'rovini yuborish va natijani `ai_analyses`ga yozish (`docs/ARCHITECTURE.md`, "AI Service" bo'limi).
- AI xolisligi talabini amalda tekshirish: bir tomonlama ma'lumot asosidagi tahlil holatining aniq belgilanishini ta'minlash (`docs/DATABASE.md`, 6-jadval izohi; `docs/DEVELOPMENT_RULES.md`, 15–16-bandlar).
- AI tahlili natijasini foydalanuvchiga (`analysis_text`, `legal_basis_summary`, iqtibos qilingan qonun moddalari bilan birga) tushunarli tarzda ko'rsatish.

**Yetkazib beriladigan natijalar (deliverables):**

- To'liq ishlaydigan nizo yaratish, tomonlarning fakt kiritish va AI tahlilini kutish/ko'rish oqimi.
- AI Service integratsiyasi — hech qanday holatda klientdan to'g'ridan-to'g'ri chaqirilmaydigan, faqat backend orqali ishlaydigan chaqiruv yo'li.
- Qonunlar lug'ati (`laws`) uchun admin boshqaruv ekrani (ma'lumotnoma sifatida).
- AI tahlili natijasi va unga bog'langan qonun moddalari ko'rsatiladigan tafsilot ekrani.
- Nizoga oid barcha RLS siyosatlari (ikkala tomon ko'rish huquqi, faqat service role yozadigan `ai_analyses`) amalda tekshirilgan.

## Phase 4

Bosqich 4 maqsadi — MVP'ning majburiy arxitektura talabi bo'lgan Offline-First imkoniyatini, oldingi bosqichlarda qurilgan murojaat va nizo oqimlariga to'liq bog'lab, amalga oshirish.

**Maqsadlar:**

- Local Storage qatlamini implementatsiya qilish — qoralama/navbatdagi yozuvlar, navbatdagi fayllar, AI vazifalari navbati va ularning sinxronizatsiya metama'lumoti uchun (`docs/ARCHITECTURE.md`, "Local Storage" bo'limi).
- `data/datasources/` ichida har bir feature (`appeals`, `disputes`) uchun mahalliy datasource'ni remote datasource bilan bir xil shartnoma asosida qo'shish.
- Sync Engine'ni ishga tushirish — navbatni FIFO tartibda qayta ishlash, idempotentlik, ortib boruvchi kutish oralig'i bilan qayta urinish (`docs/ARCHITECTURE.md`, "Sync Engine" bo'limi).
- Network State Handling'ni joriy etish — onlayn/oflayn holatini real vaqtda kuzatish va Sync Engine'ni avtomatik ishga tushirish (`docs/ARCHITECTURE.md`, "Network State Handling" bo'limi).
- Conflict Resolution strategiyasini amalga oshirish — holat (`status`) bo'yicha server ustuvorligi, tarkib (content) bo'yicha ruxsat etilgan holatdagina mahalliy o'zgarishni qabul qilish (`docs/ARCHITECTURE.md`, "Conflict Resolution" bo'limi).
- Foydalanuvchiga shaffof holat ko'rsatish — "lokal saqlangan / yuborilishi kutilmoqda / sinxronlanmoqda / serverga yetkazildi" belgilarini UI darajasida amalga oshirish (`docs/UI.md`, "Design Principles" bo'limi).

**Yetkazib beriladigan natijalar (deliverables):**

- Internet o'chirilgan holatda ham murojaat/nizo yaratish, tahrirlash va fayl biriktirish imkoniyati amalda tasdiqlangan (qo'lda sinovdan o'tkazilgan).
- Internet qaytganda barcha navbatdagi yozuvlar, fayllar va AI so'rovlarining foydalanuvchi aralashuvisiz avtomatik sinxronlanishi.
- Sinxronizatsiya muvaffaqiyatsiz bo'lganda qayta urinish mexanizmining amalda ishlashi va foydalanuvchiga tegishli holat ko'rsatilishi.
- Global tarmoq/sinxronizatsiya holati ko'rsatkichi barcha asosiy ekranlarda mavjud.
- Ziddiyat (conflict) senariylari (masalan admin offline paytda holatni o'zgartirgan) qo'lda sinovdan o'tkazilib, foydalanuvchi hech qachon "boshi berk" holatga tushmasligi tasdiqlangan.

## Milestones

Quyidagi bosqichlararo nazorat nuqtalari loyihaning MVP'ga qarab haqiqiy siljishini o'lchash uchun belgilangan; har bir milestone tegishli bosqich audit talabidan o'tgandan so'ng yakunlangan hisoblanadi (`docs/DEVELOPMENT_RULES.md`, 20–23-bandlar).

- **M0 — Poydevor tayyor:** hujjatlash (vision, arxitektura, DB, xavfsizlik, UI, roadmap) va Dart skeleti yakunlangan (Bosqich 0, allaqachon bajarilgan).
- **M1 — Foydalanuvchi tizimga kira oladi:** haqiqiy Supabase loyihasi, RLS va to'liq autentifikatsiya oqimi ishlayapti; foydalanuvchi ro'yxatdan o'tib, rolga mos bo'sh asosiy ekranni ko'radi (Bosqich 1 yakuni).
- **M2 — Birinchi uchtan-uchga (end-to-end) oqim:** fuqaro murojaat yaratib, yuboradi va admin unga rasmiy javob kiritadi — butun zanjir haqiqiy Supabase'da ishlaydi (Bosqich 2 yakuni).
- **M3 — AI tahlili jonli:** ikki tomon nizo ochib, faktlarini kiritadi va AI Service tomonidan hosil qilingan tarafsiz tahlilni ko'radi (Bosqich 3 yakuni).
- **M4 — Offline-first tasdiqlangan:** internet uzilgan holatda murojaat/nizo yaratib, internet qaytganda avtomatik sinxronlanishi qo'lda sinovdan o'tkazilib tasdiqlangan (Bosqich 4 yakuni) — bu MVP'ning eng kritik, majburiy milestone'i.
- **M5 — Admin va xabarnomalar to'liq:** admin boshqaruv paneli (ma'lumotnomalar, audit jurnali ko'rish) va push xabarnoma yetkazish to'liq ishlaydi (Bosqich 5 yakuni).
- **M6 — Reliz nomzodi (Release Candidate):** barcha Security/Performance/UX auditlari o'tkazilgan, `docs/SECURITY.md`dagi "Security Checklist" to'liq bajarilgan, critical darajadagi kamchilik qolmagan (Bosqich 6 yakuni).

## Release Criteria

MVP quyidagi shartlarning **barchasi** bajarilmaguncha reliz sifatida chiqarilmaydi (`docs/DEVELOPMENT_RULES.md`, 22–24-bandlar):

- **Funksional to'liqlik:** MVP Scope bo'limida belgilangan ikkala asosiy oqim (murojaat, nizo) va uchala rol (Fuqaro, Tashkilot, Admin) uchtan-uchga ishlaydi.
- **Offline-first talabi to'liq bajarilgan:** internet yo'qligi hech qachon ilovani bloklamaydi; murojaat/nizo offline yaratiladi, fayllar vaqtincha lokal saqlanadi, AI vazifalari navbatga qo'yiladi, internet qaytganda avtomatik va ishonchli (qayta urinish bilan) sinxronlanadi — bu shart muzokara qilinmaydigan (non-negotiable) minimal talab hisoblanadi.
- **Xavfsizlik audit talabi:** `docs/SECURITY.md`dagi "Security Checklist" bo'limining barcha bandlari tasdiqlangan; critical darajadagi xavfsizlik kamchiligi mavjud emas (`docs/DEVELOPMENT_RULES.md`, 24-band).
- **Audit balli:** Security, Performance va UX auditlarining har biri 95 balldan past bo'lmasligi kerak (`docs/DEVELOPMENT_RULES.md`, 23-band).
- **RLS to'liq qamrovi:** `docs/DATABASE.md`dagi barcha 13 jadvalda RLS yoqilgan va har bir amal uchun aniq siyosat mavjudligi tasdiqlangan.
- **"No Dead End Rule" tasdiqlangan:** barcha asosiy oqimlarda (autentifikatsiya, murojaat, nizo, sinxronizatsiya xatoligi) foydalanuvchiga har doim aniq keyingi qadam ko'rsatilishi qo'lda tekshirilgan (`docs/DEVELOPMENT_RULES.md`, 17–19-bandlar).
- **Hujjat-kod muvofiqligi:** `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/SECURITY.md`, `docs/UI.md`da tavsiflangan xatti-harakat haqiqiy implementatsiya bilan mos, farqlar aniqlangan va hujjatlashtirilgan.
- **Barcha aniqlangan kamchiliklar yopilgan:** oldingi bosqichlar va auditlarda topilgan barcha topilmalar `docs/ACTION_PLAN.md`da yozilgan va yopilgan holatda (`docs/DEVELOPMENT_RULES.md`, 25-band).

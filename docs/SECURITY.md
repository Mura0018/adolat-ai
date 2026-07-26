# SECURITY.md — Adolat AI xavfsizlik dizayni

Bu hujjat **faqat dizayn hujjati** — SQL yoki kod yo'q. Xavfsizlikka oid arxitektura qarorlarini hujjatlashtirish maqsad qilingan (`docs/DEVELOPMENT_RULES.md`, 9-band).

## Autentifikatsiya (Authentication)

- **Provayder:** Supabase Auth — foydalanuvchi identifikatsiyasi butunlay Supabase tomonidan boshqariladi, ilova o'z autentifikatsiya mexanizmini yozmaydi.
- **Kirish usullari (MVP):** telefon raqami + parol va/yoki email + parol. Telefon orqali ro'yxatdan o'tishda SMS-kod bilan tasdiqlash talab qilinadi (fuqarolarning aksariyati uchun asosiy kirish usuli telefon raqami bo'lishi kutiladi).
- **Sessiya boshqaruvi:** Supabase JWT (access token + refresh token) asosida. Access token muddati qisqa, refresh token orqali avtomatik yangilanadi.
- **Token saqlash:** mobil klientda tokenlar `Flutter Secure Storage` orqali (platforma darajasidagi shifrlangan xotira) saqlanadi — oddiy `SharedPreferences`da saqlash taqiqlanadi.
- **Parol talablari:** minimal uzunlik va murakkablik siyosati Supabase Auth sozlamalarida belgilanadi; parol hech qachon plain-text holda log yoki bazada saqlanmaydi (Supabase tomonidan hash qilinadi).
- **Sessiyani tugatish:** foydalanuvchi tizimdan chiqqanda yoki token yaroqsiz bo'lganda mahalliy tokenlar to'liq tozalanadi va foydalanuvchi kirish ekraniga yo'naltiriladi.
- **Debug loglar:** Release build'da autentifikatsiya bilan bog'liq hech qanday maxfiy ma'lumot (token, parol, SMS-kod) logga yozilmaydi (`DEVELOPMENT_RULES.md`, 11-band).

## Avtorizatsiya (Authorization) — 3 rol

Tizimda uchta foydalanuvchi roli mavjud, har biri `profiles.role` ustunida saqlanadi (`docs/DATABASE.md`, 1-jadval):

### 1. Fuqaro (`citizen`)

- Davlat organiga murojaat yuboradi va o'z murojaatlarini kuzatadi.
- Boshqa fuqaro yoki tashkilotga qarshi nizo ochadi (`disputes.initiator_id`) yoki respondent sifatida javob beradi.
- Faqat **o'ziga tegishli** yozuvlarni (murojaat, nizo, fayl, xabar) ko'radi va tahrirlaydi — boshqa foydalanuvchilarning ma'lumotlariga kirish yo'q.
- Rol ustunini (`profiles.role`) o'zi o'zgartira olmaydi.

### 2. Tashkilot (`organization`)

- `citizen` bilan bir xil huquqlarga ega (murojaat yuborish, nizoda ishtirok etish), farqi — qo'shimcha `organization_profiles` yozuvi orqali yuridik ma'lumotlar (STIR, yuridik manzil) bilan bog'langan.
- Nizoda faqat **tomon** (initiator yoki respondent) sifatida ishtirok etadi — davlat organi (`government_bodies`) tizim foydalanuvchisi emas va ushbu rolga tegishli emas.
- Egalik mantig'i `citizen` bilan bir xil: faqat o'ziga tegishli yozuvlarga kirish huquqi bor.

### 3. Admin (`admin`)

- Tizimdagi barcha jadvallarning barcha qatorlariga to'liq kirish huquqiga ega (murojaatlar, nizolar, fayllar, xabarlar, audit jurnali).
- Boshqaruv (reference) ma'lumotlarini (`legal_categories`, `government_bodies`, `laws`) yaratadi, tahrirlaydi va faollik holatini o'zgartiradi.
- Murojaat holatini (`appeals.status`) va rasmiy javobni (`official_response_text`) yangilaydi.
- `audit_log` jadvalini o'qishga yagona huquqli rol.
- MVP doirasida yurist/operator kabi oraliq rol yo'q — barcha "vakolatli inson" amallari `admin` orqali bajariladi (`docs/DATABASE.md`ga muvofiq).

**Umumiy prinsip:** avtorizatsiya asosan Supabase **RLS (Row Level Security)** siyosatlari orqali DB darajasida ta'minlanadi, ilova darajasidagi tekshiruvga tayanilmaydi — bu minimal ruxsat tamoyilini (`DEVELOPMENT_RULES.md`, 14-band) amalda ta'minlaydi.

## Supabase RLS Security

- **Standart holat — yopiq:** har bir jadvalda RLS **majburiy yoqilgan** bo'ladi; alohida `SELECT`/`INSERT`/`UPDATE`/`DELETE` siyosati yozilmagan amal avtomatik ravishda **taqiqlangan** hisoblanadi (`DEVELOPMENT_RULES.md`, 12-band: "RLS siyosatlari yozilmasdan Database ishlab chiqilmaydi").
- **Egalik (ownership) asosidagi tekshiruv:** har bir siyosat `auth.uid()` funksiyasi orqali joriy foydalanuvchini aniqlaydi va uni yozuvning tegishli egalik ustuni (`author_id`, `initiator_id`, `respondent_profile_id`, `recipient_id` va h.k.) bilan solishtiradi — bu mantiq `docs/DATABASE.md`da har bir jadval uchun alohida belgilangan.
- **Rolga bog'liq kengaytirilgan huquq:** `admin` rolidagi foydalanuvchi uchun barcha jadvallarda qo'shimcha siyosat mavjud bo'lib, u egalik cheklovisiz to'liq kirish huquqini beradi; rol tekshiruvi `profiles.role` ustuni orqali amalga oshiriladi.
- **Service role bilan ajratilgan yozuv:** AI/tizim tomonidan hosil qilinadigan nozik jadvallar (`ai_analyses`, `audit_log`, `case_status_history`, `notifications`) client tomonidan **hech qachon to'g'ridan-to'g'ri yozilmaydi** — faqat backend tomonidagi **service role** (RLS'ni chetlab o'tadigan imtiyozli kalit) orqali yoziladi. Bu soxtalashtirish (masalan, AI xulosasini o'zi o'zgartirib qo'yish) xavfini oldini oladi.
- **Mutually exclusive FK invariant:** `appeal_id`/`dispute_id`/`case_type` moslikni ta'minlovchi cheklov RLS siyosatida emas, DB darajasidagi CHECK constraint orqali ta'minlanadi — RLS faqat "kim ko'ra oladi/yoza oladi" savoliga javob beradi, "qaysi qiymat to'g'ri" savoliga emas.
- **O'zgarmas (immutable) audit yozuvlar:** `case_status_history` va `audit_log` kabi jadvallarda `UPDATE`/`DELETE` siyosati umuman berilmaydi — bu yozuvlarni hech kim (admin ham) ilova darajasida o'zgartira olmasligini kafolatlaydi.
- **Storage bucket policy:** Supabase Storage'dagi haqiqiy fayllar uchun `storage.objects` jadvalida alohida RLS siyosati, `attachments` jadvalidagi egalik mantig'iga mos ravishda sozlanadi — fayl metadatasiga kirish huquqi bilan haqiqiy faylga kirish huquqi bir xil qoidaga bo'ysunishi shart.
- **Har bir siyosat kod review'da tekshiriladi:** yangi jadval yoki ustun qo'shilganda mos RLS siyosati yozilmasdan PR birlashtirilmaydi (`DEVELOPMENT_RULES.md`, 9 va 21-bandlar).

## JWT Security

- **Token turi:** Supabase Auth tomonidan chiqarilgan standart JWT (access token) — foydalanuvchi identifikatorini (`sub` = `auth.uid()`), rolini va muddatini o'zida saqlaydi.
- **Muddat (expiry):** access token qisqa umr ko'radi (Supabase standart konfiguratsiyasi); muddati tugagach, alohida uzoq muddatli **refresh token** yordamida jimgina (foydalanuvchi bilmasdan) yangilanadi.
- **Imzo tekshiruvi:** har bir so'rovda JWT imzosi Supabase tomonidan serverda tekshiriladi; klient tomonda token mazmuniga (masalan, rolga) ishonib avtorizatsiya qarori qabul qilinmaydi — yakuniy tekshiruv har doim server/DB (RLS) darajasida.
- **Xavfsiz saqlash:** JWT (access + refresh) mobil qurilmada faqat `Flutter Secure Storage` orqali, platforma darajasidagi shifrlangan xotirada saqlanadi; oddiy fayl tizimida yoki `SharedPreferences`da saqlash taqiqlanadi.
- **Tarmoq orqali uzatish:** JWT faqat **HTTPS/TLS** ustidan uzatiladi; plain HTTP ustidan hech qanday so'rov yuborilmaydi.
- **Loglanmaslik:** JWT qiymati (to'liq yoki qisman) Release build loglariga, crash-report xizmatlariga yoki analytics tizimlariga hech qachon yozilmaydi (`DEVELOPMENT_RULES.md`, 11-band).
- **Bekor qilish (revocation):** foydalanuvchi tizimdan chiqqanda yoki parolni almashtirganda mavjud sessiya/refresh token Supabase tomonida bekor qilinadi va mahalliy nusxa darhol tozalanadi.
- **Rol o'zgarishi:** `profiles.role` DB darajasida o'zgargan taqdirda, joriy JWT'dagi eski ma'lumot emas, balki har bir so'rovda RLS siyosati orqali **joriy** `profiles.role` qiymati tekshiriladi — shu sababli rol o'zgarishi darhol kuchga kiradi, eski token muddati tugashini kutish shart emas.

## API Security

- **To'g'ridan-to'g'ri Supabase client:** MVP'da ilova maxsus backend API server orqali emas, Supabase avtogenerativ REST/Realtime API'lari orqali ishlaydi — shuning uchun "API xavfsizligi"ning katta qismi RLS siyosatlari va Supabase loyihasi sozlamalari orqali ta'minlanadi (yuqoridagi bo'limlarga qarang).
- **Nozik amallar uchun service-role chegarasi:** AI tahlili yaratish, audit yozish kabi imtiyozli amallar klientdan to'g'ridan-to'g'ri emas, faqat backend/serverless funksiya (service role kaliti bilan) orqali bajariladi — service role kaliti **hech qachon** mobil ilova binarida yoki klient kodida saqlanmaydi.
- **Maxfiy kalitlar:** `.env` fayllar va ulardagi Supabase URL/anon key/service role key GitHub'ga yuklanmaydi (`.gitignore` orqali chiqarib tashlanadi) — `DEVELOPMENT_RULES.md`, 13-band.
- **Anon key vs service role key:** mobil klientda faqat cheklangan huquqli **anon key** ishlatiladi (barcha huquq RLS orqali cheklanadi); to'liq huquqli **service role key** faqat serverda saqlanadi va ishlatiladi.
- **Kirish (input) tekshiruvi:** foydalanuvchidan kelgan barcha ma'lumot (murojaat matni, nizo tavsifi, fayl) serverga yuborishdan oldin klientda, va DB darajasida qo'shimcha constraint/validatsiya bilan tekshiriladi — faqat klient-tomon validatsiyasiga ishonilmaydi.
- **Fayl yuklash xavfsizligi:** `attachments` orqali yuklanadigan fayllar uchun ruxsat etilgan `mime_type` va maksimal `size_bytes` chegarasi belgilanadi; Storage bucket policy fayl egasi va tegishli case holatiga mos ravishda kirishni cheklaydi.
- **Rate limiting:** Supabase loyihasi darajasidagi standart so'rov cheklovlaridan tashqari, nozik endpointlar (masalan AI tahlil so'rovi, SMS-kod yuborish) uchun suiiste'mol (abuse) va ortiqcha xarajatni oldini olish maqsadida qo'shimcha cheklov ko'rib chiqiladi.
- **Xatolik xabarlari:** API xatoliklari foydalanuvchiga ichki tizim tafsilotlarini (masalan, DB struktura, stack trace) oshkor qilmaydigan umumiy shaklda ko'rsatiladi, lekin yechim yo'nalishi bilan birga (`DEVELOPMENT_RULES.md`, 17-band — No Dead End Rule).

## File Upload Security

- **Ruxsat etilgan turlar (whitelist):** `attachments.mime_type` uchun faqat oldindan belgilangan ro'yxat (masalan rasm va PDF formatlari) qabul qilinadi — ro'yxatda yo'q turdagi fayl serverga yetib borishidan oldin rad etiladi; taqiqlangan kengaytmalar (`.exe`, `.sh`, `.apk` va h.k.) ro'yxatga umuman kiritilmaydi.
- **Hajm chegarasi:** `attachments.size_bytes` uchun maksimal chegara belgilanadi; undan katta fayl yuklash so'rovi rad etiladi — bu resurs sarflab suiiste'mol qilish (abuse) va Storage xarajatining nazoratsiz o'sishini oldini oladi.
- **Fayl mazmunini tekshirish:** faqat fayl kengaytmasiga emas, fayl haqiqiy MIME turiga (magic bytes) ham tayanib tekshiruv qilinishi tavsiya etiladi — bu fayl kengaytmasini soxtalashtirib zararli fayl yuklashning oldini oladi.
- **Saqlash joyi:** haqiqiy fayl tarkibi to'g'ridan-to'g'ri jamoat (public) papkada emas, Supabase Storage'ning tegishli bucket'ida, `attachments` jadvalidagi egalik mantig'iga mos RLS/bucket policy bilan himoyalangan holda saqlanadi.
- **Nomlash (path) xavfsizligi:** `storage_path` foydalanuvchi kiritgan asl fayl nomiga emas, tizim tomonidan generatsiya qilingan noyob identifikatorga asoslanadi — bu path traversal va fayl nomlari to'qnashuvi (collision) xavfini bartaraf etadi; asl nom faqat `file_name` ustunida ko'rsatish maqsadida saqlanadi.
- **Kirish huquqi:** yuklangan faylni faqat tegishli murojaat/nizo egasi (dispute uchun ikkala tomon) va `admin` ko'ra oladi — boshqa foydalanuvchiga to'g'ridan-to'g'ri Storage havolasi orqali ham kirish berilmaydi.
- **Zararli dastur tekshiruvi:** kelgusi bosqichda (MVP doirasidan tashqarida) yuklangan fayllarni virus/zararli kontentga skanerlash xizmati bilan integratsiya ko'rib chiqilishi mumkin — bu `docs/IDEA_PARKING.md`ga yozilishi tavsiya etiladi.

## Secrets Management

- **`.env` fayllar:** Supabase URL, anon key, service role key va boshqa maxfiy konfiguratsiya qiymatlari faqat `.env` fayllarda saqlanadi va `.gitignore` orqali versiya nazoratidan chiqarib tashlanadi — GitHub'ga hech qachon yuklanmaydi (`DEVELOPMENT_RULES.md`, 13-band).
- **Kalitlarni ajratish:** klient (mobil ilova) faqat cheklangan huquqli **anon key**ga ega bo'ladi; **service role key** faqat backend/serverless muhitda saqlanadi va u yerdan tashqariga chiqarilmaydi.
- **Muhitlar (environment) bo'yicha ajratish:** development, staging va production uchun alohida Supabase loyihasi/kalitlar ishlatiladi — bitta kalit bir nechta muhitda qayta ishlatilmaydi.
- **Kalitni almashtirish (rotation):** kalit tasodifan oshkor bo'lgan (leak) taqdirda darhol Supabase loyihasi darajasida yangilanishi (rotate qilinishi) va eski kalit bekor qilinishi shart.
- **Kod ichida qattiq yozilgan (hardcoded) qiymat taqiqlanadi:** maxfiy kalit yoki parol manba kodida, commit tarixida yoki loglarda qoldirilmasligi kerak; buni oldini olish uchun commit qilishdan oldin tekshiruv amalga oshiriladi (`DEVELOPMENT_RULES.md`, 21-band).
- **CI/CD muhiti:** avtomatlashtirilgan build/deploy jarayonida maxfiy kalitlar faqat CI tizimining shifrlangan "secret" xotirasida saqlanadi, build loglarida ko'rsatilmaydi.

## Encryption

- **Uzatishda shifrlash (in transit):** klient va Supabase orasidagi barcha aloqa faqat **HTTPS/TLS** orqali amalga oshiriladi; shifrlanmagan (plain HTTP) ulanishga ruxsat berilmaydi.
- **Saqlashda shifrlash (at rest):** Supabase (PostgreSQL va Storage) tomonidan taqdim etiladigan standart at-rest shifrlash ishlatiladi — ma'lumotlar bazasi va fayl saqlash darajasida qo'shimcha infratuzilma tashkil etilmaydi.
- **Mobil qurilmada mahalliy shifrlash:** tokenlar va boshqa nozik mahalliy ma'lumotlar `Flutter Secure Storage` orqali, platforma (Android Keystore / iOS Keychain) darajasidagi shifrlangan xotirada saqlanadi — oddiy fayl tizimi yoki shifrlanmagan `SharedPreferences` ishlatilmaydi.
- **Parollar:** foydalanuvchi paroli hech qachon plain-text holda saqlanmaydi yoki uzatilmaydi — parolni hash qilish va tekshirish to'liq Supabase Auth tomonidan bajariladi, ilova o'z hash mexanizmini yozmaydi.
- **Nozik hujjat/dalil fayllari:** `attachments` orqali yuklangan hujjatlar Supabase Storage'ning shifrlangan saqlash muhitida joylashadi; ularga kirish yuqorida tavsiflangan RLS/bucket policy orqali cheklanadi.

## Audit Log Security

- **Yozish faqat service role orqali:** `audit_log` jadvaliga klient hech qachon to'g'ridan-to'g'ri yoza olmaydi — yozuv faqat backend/service role jarayoni tomonidan, tegishli amal (masalan holat o'zgarishi, admin amali) sodir bo'lganda avtomatik hosil qilinadi.
- **O'zgarmaslik (immutability):** `audit_log` uchun `UPDATE` va `DELETE` siyosati umuman berilmaydi — hech bir rol, admin ham, mavjud audit yozuvini o'zgartira yoki o'chira olmaydi; bu yozuvlarning ishonchliligini (tamper-proof) kafolatlaydi.
- **O'qish huquqi cheklangan:** `audit_log`ni faqat `admin` roli ko'ra oladi — oddiy foydalanuvchi (`citizen`/`organization`) o'ziga tegishli bo'lsa ham audit yozuviga bevosita kira olmaydi.
- **Qamrov:** nozik amallar — profil o'zgarishi, murojaat/nizo holati o'zgarishi, admin tomonidan bajarilgan amallar — majburiy ravishda audit qilinadi (`DEVELOPMENT_RULES.md`, 9-band; `docs/DATABASE.md`, 13-jadval).
- **Maxfiylik bilan muvozanat:** `audit_log.metadata` (jsonb) ichida saqlanadigan eski/yangi qiymatlarda parol, token kabi maxfiy ma'lumotlar hech qachon saqlanmaydi — faqat amalni tushunish uchun zarur bo'lgan minimal ma'lumot yoziladi.
- **Muvofiqlik (compliance) maqsadi:** audit jurnali enterprise/muvofiqlik talabini qondirish va kelgusidagi xavfsizlik auditlarida (`PROJECT_AUDIT.md`) tekshiruv izi sifatida xizmat qilish uchun mo'ljallangan.

## Rate Limiting

- **Autentifikatsiya endpointlari:** kirish (login), ro'yxatdan o'tish va SMS-kod yuborish so'rovlari IP/telefon raqami bo'yicha cheklanadi — brute-force va SMS-bombardimon (bombing) hujumlarining oldini olish uchun.
- **AI tahlil so'rovlari:** `ai_analyses` yaratishga olib keluvchi so'rovlar foydalanuvchi bo'yicha cheklanadi — bu resurs sarfini (AI xarajati) nazorat qilish va suiiste'molni oldini olish maqsadida amalga oshiriladi.
- **Umumiy Supabase cheklovi:** loyiha darajasidagi standart so'rov/tarmoq cheklovlaridan tashqari, nozik yozuv amallari (murojaat/nizo yaratish, fayl yuklash) uchun vaqt birligida ruxsat etilgan amal soni belgilanadi.
- **Cheklovga tushganda xabar:** foydalanuvchiga cheklovga yetgani aniq va tushunarli xabar bilan ko'rsatiladi, keyingi urinish uchun qachon qayta urinish mumkinligi (masalan kutish vaqti) bilan birga — bu "No Dead End Rule" (`DEVELOPMENT_RULES.md`, 17-band) talabiga mos.
- **Cheklovning joylashuvi:** asosiy cheklov server/Supabase tomonida amalga oshiriladi — faqat klient tomonidagi (UI darajasidagi) cheklovga tayanilmaydi, chunki u chetlab o'tilishi mumkin.

## Backup & Recovery

- **Avtomatik zaxira nusxalash:** Supabase tomonidan taqdim etiladigan kundalik (yoki loyiha rejasiga mos) avtomatik ma'lumotlar bazasi backup xizmatidan foydalaniladi.
- **Saqlash muddati (retention):** backup nusxalar Supabase loyihasi konfiguratsiyasida belgilangan muddat davomida saqlanadi; muddat tanlashda muvofiqlik (compliance) va audit talablari hisobga olinadi.
- **Tiklash (restore) jarayoni:** ma'lumotlar buzilishi yoki yo'qotilishi holatida so'nggi mos backup nuqtasidan (point-in-time) tiklash imkoniyati ta'minlanadi; tiklash faqat vakolatli shaxs (loyiha egasi/admin darajasidagi Supabase kirish huquqi) tomonidan amalga oshiriladi.
- **Storage fayllari:** Supabase Storage'da saqlanadigan hujjat/dalil fayllari ham ma'lumotlar bazasi bilan bir qatorda backup siyosatiga kiritiladi — faqat metadata emas, haqiqiy fayl mazmuni ham tiklanishi mumkin bo'lishi kerak.
- **Davriy tekshiruv:** backup'dan tiklash jarayoni ishlayotganini tasdiqlash uchun davriy (masalan har bir katta relizdan oldin) tiklash mashqi (restore drill) o'tkazilishi tavsiya etiladi — bu `PROJECT_AUDIT.md` doirasida kuzatiladi.
- **Falokat holatidagi rejasi (disaster recovery):** jiddiy uzilish holatida qanday tartibda harakat qilinishi (kimga xabar berish, qaysi tartibda tiklash) `Incident Response` bo'limidagi jarayon bilan bog'liq holda amalga oshiriladi.

## Monitoring

- **Xatoliklarni kuzatish:** Release build'dagi kutilmagan xatoliklar (crash, exception) maxfiy ma'lumotlarni o'z ichiga olmagan holda markazlashtirilgan monitoring/crash-report xizmatiga yuboriladi.
- **Autentifikatsiya anomaliyalari:** g'ayrioddiy kirish urinishlari (masalan bitta hisobga ketma-ket ko'p muvaffaqiyatsiz login, g'ayrioddiy joydan kirish) kuzatiladi va kerak bo'lganda cheklov/ogohlantirish trigger qilinadi.
- **RLS/avtorizatsiya xatoliklari:** kutilmagan miqdorda "ruxsat etilmagan" (RLS reject) javoblar kelishi tizimga hujum urinishi yoki noto'g'ri konfiguratsiya belgisi bo'lishi mumkin — bunday holatlar kuzatuv ostida bo'ladi.
- **Ishlash ko'rsatkichlari (performance):** API javob vaqti, AI tahlil so'rovlarining muvaffaqiyat darajasi va xarajati kabi ko'rsatkichlar muntazam kuzatiladi (`DEVELOPMENT_RULES.md`, 22-band — Performance Audit talabiga bog'liq).
- **Ogohlantirish (alerting):** kritik xatolik yoki xavfsizlik hodisasi (masalan `audit_log`ga yozishning to'satdan to'xtashi) darhol mas'ul jamoaga xabar qilinadigan tarzda sozlanadi.
- **Maxfiylik prinsipi:** monitoring/log tizimiga hech qachon parol, token yoki foydalanuvchining to'liq shaxsiy hujjat mazmuni kabi maxfiy ma'lumot yuborilmaydi — faqat texnik va agregatsiyalangan ma'lumot.

## Incident Response

- **Aniqlash:** xavfsizlik hodisasi (ma'lumot sizib chiqishi, ruxsatsiz kirish, kalitning oshkor bo'lishi) monitoring/ogohlantirish tizimi yoki tashqi xabar (masalan foydalanuvchi murojaati) orqali aniqlanadi.
- **Darhol cheklash (containment):** hodisa aniqlangach, birinchi qadam sifatida ta'sirlangan kalit(lar) bekor qilinadi/almashtiriladi (`Secrets Management` bo'limiga muvofiq), zarur bo'lsa ta'sirlangan foydalanuvchi sessiyalari majburan tugatiladi.
- **Baholash (assessment):** `audit_log` va monitoring ma'lumotlari asosida hodisaning ko'lami (qaysi ma'lumot, qancha foydalanuvchi ta'sirlangani) aniqlanadi.
- **Xabar berish:** ta'sirlangan foydalanuvchilarga va, agar qonunchilik talab qilsa, tegishli davlat organiga hodisa haqida asossiz kechiktirmasdan xabar beriladi — bu shaffoflik va foydalanuvchi ishonchini saqlash tamoyiliga asoslanadi.
- **Bartaraf etish va tiklash:** ildiz sababi (root cause) aniqlanib bartaraf etiladi, zarur bo'lsa `Backup & Recovery` jarayoni orqali ma'lumot/tizim holati tiklanadi.
- **Kritik kamchilik bo'lsa — Release taqiqlanadi:** `DEVELOPMENT_RULES.md`, 24-band talabiga muvofiq, critical darajadagi xavfsizlik kamchiligi hal qilinmaguncha yangi Release chiqarilmaydi.
- **Hodisadan keyingi tahlil (post-mortem):** har bir jiddiy hodisadan so'ng, kelgusida takrorlanmasligi uchun sabab va tuzatish choralari hujjatlashtiriladi (`docs/ACTION_PLAN.md`ga muvofiq, `DEVELOPMENT_RULES.md`, 25-band).

## Security Checklist

Har bir Release oldidan (`DEVELOPMENT_RULES.md`, 22-band — Security Audit) quyidagilar tekshiriladi:

- [ ] Barcha jadvallarda RLS yoqilgan va har bir amal (`SELECT`/`INSERT`/`UPDATE`/`DELETE`) uchun aniq siyosat yozilgan.
- [ ] `admin`dan tashqari hech qanday rol boshqa foydalanuvchining ma'lumotiga kira olmasligi tasdiqlangan.
- [ ] Service role kaliti faqat backendda saqlanadi, klient kodida yoki versiya nazoratida yo'q.
- [ ] `.env` va boshqa maxfiy fayllar `.gitignore`da va commit tarixida oshkor bo'lmagan.
- [ ] Release build'da debug/maxfiy loglar o'chirilgan.
- [ ] JWT/token faqat `Flutter Secure Storage`da saqlanayotgani va HTTPS ustidan uzatilayotgani tasdiqlangan.
- [ ] Fayl yuklash uchun MIME/hajm cheklovlari va Storage bucket policy ishlayotgani tekshirilgan.
- [ ] `audit_log` va `case_status_history` uchun `UPDATE`/`DELETE` siyosati mavjud emasligi (o'zgarmaslik) tasdiqlangan.
- [ ] Nozik endpointlar uchun rate limiting ishlayotgani tekshirilgan.
- [ ] Backup/tiklash jarayoni so'nggi marta muvaffaqiyatli sinovdan o'tgan.
- [ ] Monitoring/alerting kanallari faol va mas'ul shaxslarga yetib borayotgani tasdiqlangan.
- [ ] Aniqlangan barcha xavfsizlik topilmalari `docs/ACTION_PLAN.md`ga yozilgan va critical darajadagilar yopilgan.

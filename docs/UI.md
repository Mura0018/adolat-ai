# UI.md — Adolat AI foydalanuvchi interfeysi dizayni (MVP)

Bu hujjat **faqat dizayn hujjati** — kod yo'q. Maqsad: MVP doirasida ilova interfeysining tuzilishi, navigatsiya mantig'i va asosiy ekran oqimlarini so'z bilan tasvirlash. Vizual dizayn tizimi (ranglar, tipografiya) `lib/theme/`da, marshrutlash implementatsiyasi `lib/router/`da amalga oshiriladi; ushbu hujjat ular bilan ziddiyatga kirmaydi, faqat yuqori darajadagi qarorlarni belgilaydi. Texnologik va arxitektura konteksti uchun: `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/SECURITY.md`, `docs/DEVELOPMENT_RULES.md`.

## Design Principles

- **Ishonch va rasmiylik:** Adolat AI huquqiy yordam platformasi bo'lgani sababli, interfeys birinchi navbatda **ishonchli, sokin va rasmiy** taassurot uyg'otishi kerak — o'yinbop yoki ortiqcha bezakli elementlardan qochiladi, chunki foydalanuvchi ko'pincha stressli vaziyatda (nizo, shikoyat) ilovaga murojaat qiladi.
- **Soddalik ustuvor:** O'zbekiston fuqarolarining huquqiy savodxonligi turlicha bo'lgani sababli, interfeys murakkab yuridik atamalarni emas, sodda va tushunarli tilni ishlatadi; har bir ekran bitta aniq maqsadga xizmat qiladi, ortiqcha tanlov bilan foydalanuvchini chalg'itmaydi.
- **"No Dead End Rule" — asosiy UX tamoyili:** har bir ekran, xatolik yoki kutish holati foydalanuvchiga aniq keyingi qadamni ko'rsatadi; foydalanuvchi hech qachon "endi nima qilish kerak" degan savol bilan yolg'iz qolmaydi (`DEVELOPMENT_RULES.md`, 17–19-bandlar).
- **Holatni shaffof ko'rsatish:** murojaat/nizo holati, sinxronizatsiya holati va tarmoq holati doimo foydalanuvchiga tinch, bezovta qilmaydigan tarzda ko'rinib turadi (`docs/ARCHITECTURE.md`, "Offline-First Architecture" va "Network State Handling" bo'limlari) — foydalanuvchi hech qachon ilova nima qilayotganini taxmin qilishga majbur bo'lmaydi.
- **Yagona dizayn-tizimi:** barcha ekranlar `lib/widgets/`dagi qayta ishlatiladigan komponentlardan foydalanadi — tugmalar, maydonlar, holat ko'rsatkichlari va boshqa elementlar ilova bo'ylab bir xil ko'rinish va xatti-harakatga ega (`docs/folder_structure.md`).
- **Yorug' va qorong'i mavzu:** `lib/theme/`da belgilangan `ThemeData` orqali ilova ikkala mavzuni ham qo'llab-quvvatlaydi; matn va ranglar kontrastligi ikkala rejimda ham o'qilishi oson bo'lishini ta'minlaydi.
- **Ikki tilli qamrov:** interfeys o'zbek va ingliz tillarida ishlaydi (`lib/localization/`); matn uzunligi tarjimada o'zgarishi mumkinligi hisobga olinib, elementlar moslashuvchan (flexible) tarzda loyihalanadi.
- **Mobil-birinchi, lekin ko'p platformali:** asosiy dizayn qarorlari mobil ekran o'lchamiga mo'ljallanadi, Web versiyasida esa xuddi shu tarkib kengroq ekranga moslashtirilib (responsive) ko'rsatiladi — alohida, farqli Web-maxsus interfeys yaratilmaydi.
- **Kirish imkoniyati (accessibility):** matn o'lchami kattalashtirilishi, tugmalar yetarlicha katta bosish maydoniga ega bo'lishi va ekran o'quvchilar (screen reader) bilan mos ishlashi MVP'da hisobga olinadigan asosiy talablar.

## Navigation Structure

- **Marshrutlash asosi:** yagona markazlashgan **GoRouter** konfiguratsiyasi orqali (`lib/router/`) — har bir feature o'z marshrutini shu yerga ro'yxatdan o'tkazadi, deklarativ va bashorat qilinadigan navigatsiya ta'minlanadi (`docs/architecture.md`).
- **Autentifikatsiya to'sig'i (auth guard):** sessiyasi yo'q foydalanuvchi himoyalangan (protected) marshrutlarga kira olmaydi — avtomatik ravishda "Authentication Screens" oqimiga yo'naltiriladi; sessiyasi mavjud foydalanuvchi esa autentifikatsiya ekranlariga qaytarilmaydi (`docs/ARCHITECTURE.md`, "Authentication Flow" bo'limi).
- **Rolga qarab asosiy navigatsiya ikki shoxobchaga bo'linadi:**
  - **Fuqaro / Tashkilot uchun** — pastki navigatsiya paneli (bottom navigation) orqali asosiy bo'limlar: **Bosh sahifa**, **Murojaatlarim**, **Nizolarim**, **Xabarnomalar**, **Profil**. Ikkala rol ham bir xil navigatsiya tuzilmasidan foydalanadi (`docs/SECURITY.md`dagi teng huquq mantig'iga muvofiq), faqat Profil bo'limidagi maydonlar farq qiladi.
  - **Admin uchun** — butunlay alohida, boshqaruv (dashboard) yo'naltirilgan navigatsiya: **Murojaatlar boshqaruvi**, **Nizolar boshqaruvi**, **Ma'lumotnomalar** (huquqiy kategoriyalar, davlat organlari, qonunlar), **Audit jurnali**, **Profil**. Admin oddiy foydalanuvchi ekranlarini ko'rmaydi.
- **Ichki (nested) navigatsiya:** har bir asosiy bo'lim (masalan "Murojaatlarim") o'z ichida ro'yxat → tafsilot → amal (masalan yangi murojaat yaratish) ketma-ketligiga ega, orqaga qaytish tabiiy va bashorat qilinadigan tarzda ishlaydi.
- **Chuqur havolalar (deep links):** push xabarnomani bosish foydalanuvchini to'g'ridan-to'g'ri tegishli murojaat/nizo tafsilot ekraniga olib boradi, asosiy navigatsiya orqali qadamma-qadam o'tishni talab qilmaydi (`docs/ARCHITECTURE.md`, "Push Notifications" bo'limi).
- **Global holat ko'rsatkichi:** tarmoq/sinxronizatsiya holati (masalan "oflayn — o'zgarishlar saqlanmoqda") navigatsiya darajasidan mustaqil, doimiy ko'rinadigan elementda (masalan yuqori panel) ko'rsatiladi — bu qaysi ekranda bo'lishidan qat'i nazar bir xilda mavjud.

## User Roles

Interfeys uchta rol uchun bir xil emas — rol UI tarkibi va navigatsiya tuzilmasini belgilaydi (`docs/SECURITY.md`, "Avtorizatsiya" bo'limidagi huquq asosida):

- **Fuqaro (`citizen`):** to'liq foydalanuvchi tajribasi — murojaat va nizo yaratish, kuzatish, fayl biriktirish, AI tahlili va rasmiy javoblarni ko'rish. Profil ekrani asosiy shaxsiy ma'lumotlar (ism, telefon, avatar) bilan cheklangan.
- **Tashkilot (`organization`):** Fuqaro bilan **bir xil ekran va navigatsiya tuzilmasidan** foydalanadi — murojaat/nizo oqimlari farqlanmaydi. Yagona farq: Profil bo'limida qo'shimcha yuridik ma'lumotlar (tashkilot nomi, STIR, yuridik manzil) ko'rsatiladi va tahrirlanadi (`docs/DATABASE.md`, `organization_profiles` jadvali).
- **Admin (`admin`):** butunlay alohida interfeys tajribasi — oddiy foydalanuvchi murojaat/nizo yaratish ekranlarini ko'rmaydi, buning o'rniga barcha murojaat/nizolarni ko'rib chiqish, holatini yangilash, rasmiy javob kiritish va ma'lumotnomalarni (huquqiy kategoriyalar, davlat organlari, qonunlar) boshqarish uchun mo'ljallangan boshqaruv (dashboard) interfeysiga ega. Admin interfeysi ko'proq jadval/ro'yxat va filtrlash imkoniyatlariga yo'naltirilgan, kamroq "hikoya asosidagi" (narrative) oqimga ega.
- **Rolning UI'ga ta'siri statik:** foydalanuvchi ilova ichida rolini o'zi o'zgartira olmaydi (`docs/SECURITY.md`ga muvofiq) — shuning uchun interfeys sessiya davomida bitta rolga mos holatda qoladi, rol almashtirish ekrani mavjud emas.

## App Entry Flow

1. **Splash ekran:** ilova ochilganda qisqa muddatli boshlang'ich ekran ko'rsatiladi, shu vaqt ichida mavjud sessiya (agar bo'lsa) `Flutter Secure Storage`dan tekshiriladi.
2. **Sessiya mavjud bo'lsa:** foydalanuvchi to'g'ridan-to'g'ri o'z roliga mos asosiy ekranga (Bosh sahifa yoki Admin dashboard) yo'naltiriladi — qayta kirish talab qilinmaydi. Bu qadam internetga bog'liq emas: mahalliy saqlangan sessiya asosida ishlaydi (`docs/ARCHITECTURE.md`, "Authentication Flow" bo'limidagi offline holat izohi).
3. **Sessiya mavjud emas va birinchi marta ishga tushirilgan bo'lsa:** foydalanuvchiga ilova imkoniyatlarini qisqacha tanishtiruvchi kirish (onboarding) ekranlari ko'rsatilishi mumkin, so'ng "Authentication Screens" oqimiga o'tadi.
4. **Sessiya mavjud emas, lekin ilova avval ishlatilgan bo'lsa:** onboarding qayta ko'rsatilmaydi, foydalanuvchi to'g'ridan-to'g'ri kirish ekraniga yo'naltiriladi.
5. **Internet holatiga bog'liqlik:** birinchi marta autentifikatsiya qilish uchun internet aloqasi zarur (Supabase Auth markazlashgan xizmat bo'lgani sababli); agar foydalanuvchida hali hech qanday sessiya bo'lmasa va internet mavjud bo'lmasa, bu holat foydalanuvchiga "No Dead End Rule"ga muvofiq — nima uchun kirib bo'lmayotgani va internet tiklanganda avtomatik davom etilishi aniq tushuntirilgan holda ko'rsatiladi (qattiq, tushuntirishsiz xatolik sifatida emas).
6. **Keyingi ishga tushirishlar:** sessiya bir marta o'rnatilgach, ilova tarmoq holatidan qat'i nazar ochiladi va foydalanishda davom etadi (`docs/ARCHITECTURE.md`, "Offline-First Architecture" bo'limi).

## Authentication Screens

- **Ro'yxatdan o'tish turi tanlash:** foydalanuvchi ro'yxatdan o'tishni boshlaganda, **Fuqaro** yoki **Tashkilot** sifatida ro'yxatdan o'tishni tanlaydi — bu tanlov boshlang'ich rolni belgilaydi (`docs/ARCHITECTURE.md`, "Authentication Flow" bo'limi).
- **Fuqaro ro'yxatdan o'tish shakli:** telefon raqami (asosiy) yoki email, parol va to'liq ism kabi asosiy maydonlarni o'z ichiga oladi.
- **Tashkilot ro'yxatdan o'tish shakli:** yuqoridagi asosiy maydonlarga qo'shimcha ravishda tashkilot nomi, STIR va yuridik manzil kabi maydonlarni ham so'raydi (`docs/DATABASE.md`, `organization_profiles` jadvali) — bu qo'shimcha maydonlar alohida qadam yoki kengaytirilgan shakl sifatida taqdim etilishi mumkin.
- **Telefon tasdiqlash (SMS) ekrani:** telefon raqami orqali ro'yxatdan o'tganda, foydalanuvchidan SMS orqali yuborilgan tasdiqlash kodini kiritish so'raladi; kodni qayta yuborish va kutish vaqti aniq ko'rsatiladi.
- **Kirish (login) ekrani:** telefon/email va parol maydonlari, shuningdek parolni unutgan foydalanuvchi uchun tiklash havolasi bilan.
- **Parolni tiklash oqimi:** foydalanuvchi telefon/email orqali parolni tiklash so'rovini yuboradi, tasdiqlash kodi/havola orqali yangi parol o'rnatadi.
- **Yuklanish va xatolik holatlari:** har bir autentifikatsiya amali (yuborish, tasdiqlash, kirish) davomida aniq yuklanish ko'rsatkichi va, xatolik yuz bersa, tushunarli sabab hamda keyingi qadam (masalan "qayta urinib ko'ring" yoki "kodni qayta yuboring") bilan ko'rsatiladi.
- **Chiqish (logout) tasdiqlashi:** foydalanuvchi tizimdan chiqishni tanlaganda, tasodifiy bosishning oldini olish uchun qisqa tasdiqlash so'raladi.
- **Xavfsizlik bilan bog'liq cheklov:** bu ekranlarning hech biri parol yoki tasdiqlash kodini oddiy matn ko'rinishida ekranda saqlab qolmaydi yoki logga yozmaydi (`docs/SECURITY.md`, "Autentifikatsiya" va "JWT Security" bo'limlari).

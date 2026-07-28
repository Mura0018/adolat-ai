# ADR-005: AI vendor uzilishi/fallback strategiyasi

**Status:** Taklif qilingan

**Darajasi:** High/Medium (Zero-Regret Audit — AI Service ishonchliligi topilmasi)

**Bog'liq hujjatlar:** `docs/ARCHITECTURE.md` ("AI Service" bo'limi — "Asinxron tabiat" qismi), `docs/DATABASE.md` (6-jadval `disputes.status`, `ai_analyzing` holati)

---

## Problem

`docs/ARCHITECTURE.md` AI Service'ni "alohida mantiqiy komponent" deb tavsiflaydi, lekin uning **aniq vendor/hosting muhiti** ("Supabase Edge Function yoki alohida backend xizmati") ataylab MVP arxitektura darajasidan chuqurroq belgilanmagan deb qoldirilgan. Bu o'zi uchun muammo emas — lekin buning natijasida quyidagilar ham loyihalashtirilmagan:

- AI vendor (masalan tashqi API provayder) vaqtincha ishlamay qolsa nima bo'ladi.
- AI so'rovi xato bilan tugasa (masalan noto'g'ri format, timeout) qanday qayta ishlanadi.
- Vendor model versiyasini o'zgartirsa/eskirtirsa (deprecate qilsa), tizim qanday moslashadi.
- Vaqt o'tishi bilan AI natijasi sifati "sirg'alib ketishi" (prompt/model drift) qanday aniqlanadi.

`disputes.status` holat ketma-ketligida `ai_analyzing` — AI tahlili tugashini kutayotgan oraliq holat. Agar AI so'rovi hech qachon muvaffaqiyatli yoki muvaffaqiyatsiz tugamasa (masalan vendor tinch uziladi, hech qanday javob yoki xato qaytarmaydi), nizo bu holatda **abadiy** qolib ketishi mumkin — hozirgi dizaynda bu holatdan chiqish yo'li yo'q.

## Nima uchun muhim

- Bu — mahsulotning **eng ko'zga ko'ringan** ishonchlilik nuqtasi bo'lishi mumkin: agar AI tahlili "osilib qolsa", foydalanuvchi o'z nizosi hech qachon hal qilinmasligini ko'radi — bu to'g'ridan-to'g'ri `DEVELOPMENT_RULES.md`ning "No Dead End Rule" (17–19-band) talabini buzadi, garchi buzilish sababi UI emas, backend infratuzilma bo'lsa ham.
- Tashqi AI vendorlar (qaysi biri tanlanishidan qat'i nazar) davriy uzilishlar, tezlik cheklovlari (rate limits) va model eskirishi bilan tanilgan — bu **kutilmagan holat emas, balki rejalashtirilishi kerak bo'lgan normal holat**.
- 1 million foydalanuvchida, hatto kamdan-kam (masalan 0.5%) muvaffaqiyatsizlik darajasi ham mutlaq sonda minglab "osilib qolgan" nizo/murojaatni anglatadi — bu operatsion yuk (admin qo'lda tozalashi kerak bo'ladi) va obro' zarariga aylanadi.

## Ko'rib chiqilgan variantlar

**A. Status-quo — bitta vendor, aniq xatolik/timeout siyosati yo'q, muammolar qo'lda (admin monitoring orqali) aniqlanadi**
- ➕ Eng tez ishga tushirish, MVP uchun eng kam ish.
- ➖ `ai_analyzing` holatida "abadiy osilib qolish" xavfi to'liq ochiq qoladi; operatsion yuk butunlay qo'lda kuzatuvga tushadi, bu miqyoslanmaydi.

**B. Bitta vendor + aniq timeout/retry/eskalatsiya siyosati (vendor almashtirilmaydi, lekin muvaffaqiyatsizlik holati aniq boshqariladi)**
- ➕ Nisbatan kam qo'shimcha murakkablik; asosiy "abadiy osilib qolish" muammosini hal qiladi (timeout'dan keyin holat `ai_analyzing`dan chiqariladi, foydalanuvchiga/admin'ga xabar beriladi, qayta urinish navbatga qo'yiladi).
- ➖ Agar vendor uzoq muddat (soatlab/kunlab) ishlamasa, tizim hamon to'liq to'xtab qoladi — yagona nuqta xatosi (single point of failure) saqlanib qoladi.

**C. Bitta asosiy vendor + avtomatik almashtiriladigan zaxira (fallback) vendor**
- ➕ Eng yuqori mavjudlik (availability) — asosiy vendor uzilganda tizim ishlashda davom etadi.
- ➖ Eng qimmat va murakkab: ikkita vendor bilan integratsiya, ikkalasining natijalari izchilligini (sifat, format) ta'minlash, ikki barobar xarajat nazorati (ADR-004 bilan bog'liq) kerak bo'ladi. MVP bosqichida haddan tashqari erta optimallashtirish bo'lishi mumkin.

**D. Vendor-agnostik abstraktsiya qatlami (AI Service uchun ichki interfeys/shartnoma) + B'dagi timeout/retry/eskalatsiya siyosati, lekin boshida faqat bitta vendor ulanadi — fallback (C) keyinroq, hajm buni oqlaganda qo'shiladi**
- ➕ B'ning soddaligini saqlaydi, lekin kelajakda C'ga o'tishni **arzon** qiladi, chunki vendor-maxsus kod alohida qatlamda izolyatsiya qilinadi (xuddi `data/datasources/` Supabase'ni `domain`dan izolyatsiya qilgani kabi, Clean Architecture tamoyiliga muvofiq).
- ➖ Boshida biroz qo'shimcha loyihalash ishi (abstraktsiya interfeysini to'g'ri chizish) talab qiladi, garchi amalga oshirish C'dan ancha yengil bo'lsa ham.

## Afzallik va kamchiliklar (qisqa xulosa)

| Variant | "Abadiy osilib qolish"dan himoya | Vendor uzilishiga chidamlilik | Boshlang'ich murakkablik | Kelajakka moslashuvchanlik |
|---|---|---|---|---|
| A — Status-quo | Yo'q | Yo'q | Eng past | Past |
| B — Timeout/retry | Ha | Qisman (uzoq uzilishda yo'q) | Past-o'rta | O'rta |
| C — Faol fallback | Ha | Yuqori | Yuqori | Yuqori (lekin erta) |
| D — Abstraktsiya + B, keyin C | Ha | Boshida B kabi, keyin oshiriladi | O'rta | Eng yuqori |

## Tavsiya etilgan qaror

**Variant D** — MVP uchun to'g'ri muvozanat:

1. AI Service uchun ichki Dart/backend interfeysi (masalan `AiAnalysisProvider` shartnomasi) loyihalanadi — bu Clean Architecture'dagi `domain/repositories/` naqshiga o'xshash, lekin backend/serverless tomonda: qaysi aniq vendor chaqirilishidan qat'i nazar, chaqiruvchi kod (holat mashinasi, `case_status_history` yozuvchi mantiq) faqat shu interfeys bilan ishlaydi.
2. Boshida bitta vendor ulanadi, lekin **aniq timeout** (masalan N soniya/daqiqa) va **aniq xatolik holati** belgilanadi: agar AI so'rovi timeout yoki xato bilan tugasa, `disputes`/`appeals` holati `ai_analyzing`da qolmaydi — yoki cheklangan sonli avtomatik qayta urinishdan keyin "AI tahlili kechiktirildi, admin ko'rib chiqmoqda" kabi oraliq holatga o'tadi va tegishli `notifications` yozuvi orqali foydalanuvchiga xabar beriladi.
3. Fallback vendor (Variant C) — hozircha amalga oshirilmaydi, lekin abstraktsiya tufayli kelajakda qo'shilishi `data/datasources/`ga yangi implementatsiya qo'shishdan farq qilmaydi.

## Uzoq muddatli ta'sir

Vendor-agnostik abstraktsiyani boshidanoq loyihalash — loyihaning o'zi allaqachon har joyda amal qiladigan tamoyilning (Clean Architecture — "Supabase o'rniga boshqa backend kerak bo'lsa, faqat `data/` qatlami o'zgaradi", `docs/ARCHITECTURE.md`) tabiiy davomi. Buni loyihalamasdan boshlash — AI Service kodini vendor'ning o'ziga xos SDK/API shakliga qattiq bog'lab qo'yadi, keyinchalik vendor almashtirish yoki fallback qo'shish butun AI Service'ni qayta yozishga aylanadi.

## Migratsiya ta'siri

To'g'ridan-to'g'ri ma'lumotlar bazasi migratsiyasi talab qilmaydi — bu backend/AI Service kod arxitekturasi qarori. Bilvosita ta'sir: `case_status_history`/`notifications`ga yozuvchi mantiq AI muvaffaqiyatsizlik holatini alohida "sabab" sifatida yozishi kerak bo'lishi mumkin (masalan `to_status`/`note` ustunlarida) — bu mavjud sxema doirasida, yangi ustun qo'shmasdan amalga oshiriladi.

## Xavfsizlik ta'siri

To'g'ridan-to'g'ri xavfsizlik ta'siri cheklangan, lekin bitta muhim jihat bor: agar fallback vendor kelajakda qo'shilsa, ikkala vendorga ham bir xil "faqat service-role orqali chaqiriladi, klient hech qachon to'g'ridan-to'g'ri chaqirmaydi" tamoyili (`docs/SECURITY.md`, "API Security") qat'iy qo'llanilishi shart — abstraktsiya qatlami bu tamoyilni ikkala implementatsiya uchun ham majburiy qiladi, bu xavfsizlik nuqtai nazaridan foydali yon ta'sir.

## Huquqiy/muvofiqlik ta'siri

Bilvosita: agar AI tahlili tizimli ravishda "osilib qolsa" va foydalanuvchi o'z murojaati/nizosi bo'yicha javob ololmasa, bu mahsulotning asosiy va'dasini (adolatga tezkor kirish) buzadi — huquqiy majburiyat emas, lekin ijtimoiy-mahsulot maqsadiga bevosita zid (`docs/ROADMAP.md`, "Project Vision").

## Xarajat ta'siri

Variant D'ning qo'shimcha xarajati minimal (interfeys loyihalash vaqti). Variant C (faol fallback)ning xarajati ancha yuqori bo'lardi (ikkinchi vendor bilan integratsiya + doimiy ikki barobar potentsial xarajat, agar noto'g'ri sozlansa) — shuning uchun uni hozir emas, hajm buni oqlaganda amalga oshirish tavsiya etiladi.

## Yakuniy tavsiya

Variant D'ni AI Service'ning boshlang'ich dizayni sifatida qabul qilish: vendor-agnostik ichki interfeys + aniq timeout/xatolik-holat siyosati Phase 3 boshlanishidan oldin belgilanadi; faol fallback vendor (Variant C) `docs/IDEA_PARKING.md`ga kelgusi kengaytirish sifatida yoziladi, real vendor uzilish statistikasi to'plangandan keyin qayta ko'rib chiqiladi.

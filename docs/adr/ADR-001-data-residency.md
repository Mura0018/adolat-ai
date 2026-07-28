# ADR-001: Data Residency — O'zbekiston shaxsiy ma'lumotlari qonuni vs Supabase hosting

**Status:** Bloklangan — tashqi huquqiy tasdiqlash kutilmoqda (2026-07-28 holatiga hali so'ralmagan). Bu ADR kod yoki migratsiya o'zgarishini **talab qilmaydi**, faqat qaror qabul qilish jarayonini boshlaydi. Claude Code bu blokerni o'zi hal qila olmaydi — huquqshunos bilan aloqa loyiha egasining vazifasi.

**Bloklanish sababi:** ADR-001'ning "Tavsiya etilgan qaror" bo'limidagi 1-qadam ("Huquqiy tekshiruv") hali bajarilmagan.

**Keyingi qadam:** O'zbekiston shaxsiy ma'lumotlar qonunchiligi bo'yicha malakali huquqshunos/maslahatchiga rasmiy so'rov yuborish (quyidagi "Tavsiya etilgan qaror" bo'limidagi 3 ta savol bilan).

**Mas'ul shaxs (Owner):** loyiha egasi (Claude Code emas — bu ADR'ning o'zida ham qayd etilganidek, yakuniy huquqiy xulosani Claude Code bera olmaydi).

**Darajasi:** Critical (Zero-Regret Audit, Critical topilma #1)

**Bog'liq hujjatlar:** `docs/ARCHITECTURE.md` ("Supabase Backend", "Deployment Architecture" bo'limlari), `docs/SECURITY.md` (hech qanday joyda data residency tilga olinmagan)

---

## Problem

Adolat AI'ning butun backend arxitekturasi — Autentifikatsiya (Supabase Auth), ma'lumotlar bazasi (Supabase PostgreSQL + RLS), fayl saqlash (Supabase Storage) — bitta boshqariladigan platforma, **Supabase**ga tayanadi. Supabase loyihalari standart holatda AWS infratuzilmasida, tanlangan mintaqada (odatda AQSh, Yevropa yoki Singapur mintaqalarida) joylashadi — O'zbekiston hududida rasmiy Supabase mintaqasi mavjud emas.

O'zbekiston Respublikasining shaxsiy ma'lumotlar to'g'risidagi qonunchiligi fuqarolarning shaxsiy ma'lumotlarini O'zbekiston hududida joylashgan texnik vositalar (serverlar) orqali yig'ish va dastlabki qayta ishlashni talab qiladigan lokalizatsiya qoidalarini o'z ichiga oladi. Bu talabning aniq ko'lami (qaysi turdagi ma'lumot, qanday istisnolar, xorijiy bulutli infratuzilturadan foydalanish uchun qanday shartlar mavjudligi) ushbu loyiha doirasida **hali yuridik jihatdan tekshirilmagan**.

Adolat AI davlat organlariga yuboriladigan murojaatlar (`appeals`) va fuqarolar/tashkilotlar o'rtasidagi nizolar (`disputes`) — bevosita davlat bilan aloqador, yuqori nozik toifadagi shaxsiy ma'lumotlarni qayta ishlaydi.

## Nima uchun muhim

- **Muvofiq bo'lmaslik oqibati past ehtimolli emas** — O'zbekistonda xorijiy hostingda joylashgan xizmatlarning lokalizatsiya talabiga muvofiq emasligi sababli cheklangan/bloklangan holatlar rasmiy amaliyotda kuzatilgan. Bu abstrakt xavf emas.
- **Loyiha davlat mavzusiga bevosita aloqador** — bu oddiy iste'molchi ilovasi emas, davlat organlariga murojaat yuboruvchi rasmiy platforma; bunday platformalar odatda kattaroq rag'batlantiruvchi/nazorat e'tiboriga tushadi.
- **1 million foydalanuvchi darajasida ko'rinuvchanlik keskin oshadi** — kichik miqyosda e'tiborga tushmasligi mumkin bo'lgan narsa, milliy miqyosda albatta tekshiriladi.
- **Butun texnik poydevor shu qarorga bog'liq** — Auth, 4 ta migratsiyada yozilgan barcha RLS siyosatlari, Storage bucket policy'lari — barchasi Supabase'ning o'ziga xos xususiyatlariga (masalan `auth.uid()`, `storage.foldername()`) qattiq bog'langan. Bu "portable" arxitektura emas.

## Ko'rib chiqilgan variantlar

**A. Status-quo — hech narsa o'zgartirilmaydi, Supabase (xorijiy hosting) davom etadi**
- ➕ Qo'shimcha xarajat yoki ish yo'q, rivojlanish tezligi saqlanadi.
- ➖ Muvofiqlik xavfi hal qilinmagan holda qoladi; loyiha o'sgan sari xavf ham o'sadi, lekin uni keyinroq bartaraf etish tobora qimmatlashadi.

**B. Supabase bilan mintaqaviy/maxsus joylashtirish variantini muzokara qilish (agar mavjud bo'lsa — masalan alohida enterprise shartnoma yoki self-hosted Supabase O'zbekiston hududidagi provayderda)**
- ➕ Mavjud kodning katta qismini (RLS, Auth trigger'lari, Storage siyosati) saqlab qolish mumkin — Supabase o'zi ochiq manba, self-hosting texnik jihatdan mumkin.
- ➖ Self-hosted Supabase'ni operatsion boshqarish (yangilanishlar, monitoring, miqyoslash) to'liq boshqariladigan xizmatga qaraganda sezilarli ko'proq DevOps resursi talab qiladi; O'zbekistonda mos datacenter/cloud provayder topish alohida tadqiqot talab qiladi.

**C. To'liq mustaqil migratsiya — O'zbekiston hududida joylashgan mustaqil boshqariladigan PostgreSQL + o'z Auth/Storage yechimi**
- ➕ Eng yuqori huquqiy ishonch darajasi; uzoq muddatda platformadan mustaqillik (vendor lock-in yo'qoladi).
- ➖ Eng qimmat va eng uzoq variant: Supabase Auth'dan parol hash'larini eksport qilish odatda mumkin emas — bu **barcha mavjud foydalanuvchilar uchun majburiy parolni tiklash** talab qiladi; barcha RLS siyosatlari (hozirgi 2 ta migratsiya, 26 siyosat + 4 funksiya) muqobil avtorizatsiya modeliga (masalan o'z middleware/API qatlami) qayta yozilishi kerak; Storage butunlay ko'chiriladi.

**D. Gibrid — nozik PII (fuqaro F.I.Sh, telefon, murojaat/nizo matni) mahalliy serverda, nozik bo'lmagan/agregatlangan ma'lumot (masalan `legal_categories`, `laws` lug'ati) Supabase'da qoladi**
- ➕ Eng nozik ma'lumot uchun muvofiqlikni ta'minlaydi, boshqariladigan xizmatning ba'zi afzalliklarini saqlaydi.
- ➖ Ikkita backend'ni bir vaqtda boshqarish — eng murakkab arxitektura, "mutually exclusive FK" naqshidan ham murakkabroq muvofiqlashtirish talab qiladi (masalan `appeals.body_text` bir joyda, `appeals.status` boshqa joyda bo'lsa, tranzaksion izchillikni ta'minlash qiyinlashadi). Ehtimol amalda C dan ham qimmatroq va xatoga moyilroq.

## Afzallik va kamchiliklar (qisqa jadval)

| Variant | Amalga oshirish narxi | Muvofiqlik ishonchi | Operatsion yuk | Tezlik (hozir) |
|---|---|---|---|---|
| A — Status-quo | Yo'q | Past/noaniq | Past | Eng tez |
| B — Supabase maxsus joylashuv | O'rta | Yuqori (agar mavjud bo'lsa) | O'rta-yuqori | O'rta |
| C — To'liq mustaqil migratsiya | Juda yuqori | Eng yuqori | Yuqori | Sekin |
| D — Gibrid | Yuqori (murakkablik) | Yuqori | Eng yuqori | Sekin |

## Tavsiya etilgan qaror

**Bu ADR bo'yicha texnik qaror HOZIR qabul qilinmaydi** — chunki bu birinchi navbatda huquqiy fakt masalasi, texnik tanlov emas. Tavsiya etilgan darhol harakat:

1. **Huquqiy tekshiruv** — O'zbekiston shaxsiy ma'lumotlar qonunchiligi bo'yicha malakali huquqshunos/maslahatchi bilan rasmiy so'rov: (a) `appeals`/`disputes`/`profiles` kabi ma'lumotlar lokalizatsiya talabiga tortiladimi, (b) agar tortilsa, xorijiy bulutli infratuzilma (Supabase) qanday shartlarda ruxsat etiladi (masalan faqat zaxira nusxa xorijda, asosiy nusxa mahalliy bo'lsa yetarlimi), (c) amaldagi istisnolar yoki litsenziyalash yo'llari bormi.
2. Javobga qarab: agar Supabase muvofiq bo'lsa — ADR "Qabul qilingan (A)" holatiga o'tadi, hech narsa o'zgarmaydi. Agar muvofiq bo'lmasa — variant B birinchi navbatda ko'rib chiqiladi (eng kam buzuvchi), C faqat B imkonsiz bo'lsa.
3. Huquqiy javob kelmaguncha, **yangi RLS siyosati yoki Supabase'ga xos yangi xususiyat qo'shishda ehtiyot bo'lish** tavsiya etiladi — imkon qadar, kelajakda boshqa backend'ga ko'chirish qiyinlashtiruvchi Supabase-maxsus naqshlardan (masalan `storage.foldername()`ga chuqur bog'liqlik) qochish foydali bo'lardi, lekin bu MVP tezligini pasaytirmasligi kerak — muvozanat huquqiy javobdan keyin aniqlanadi.

## Uzoq muddatli ta'sir

Agar bu masala hal qilinmasdan qoldirilsa, har bir keyingi Phase (6, 7, ...) yana bir qatlam Supabase-maxsus kod qo'shadi (yangi RLS siyosatlari, yangi Storage bucket'lar, ehtimol Supabase Edge Functions AI Service uchun) — bu "texnik qarz" emas, balki **migratsiya narxining monoton o'sishi**. Har bir kechiktirilgan oy migratsiyani qimmatlashtiradi, chunki ko'proq foydalanuvchi ma'lumoti, ko'proq bog'liq kod va ko'proq operatsion odat (jamoa Supabase konsoli/CLI'siga o'rganib qoladi) to'planadi.

## Migratsiya ta'siri

Agar variant C yoki D tanlansa:
- **Auth:** barcha foydalanuvchilar uchun majburiy parolni tiklash (Supabase parol hash formatini eksport qilib bo'lmaydi) — bu foydalanuvchi tajribasiga sezilarli ta'sir qiladi va alohida xabar/UX rejasi talab qiladi.
- **Database:** 4 ta mavjud migratsiya (`20260726000001`–`20260728000001`) yangi platforma uchun qayta yozilishi yoki moslashtirilishi kerak; RLS ekvivalenti (agar Postgres asosli bo'lmasa) noldan loyihalanadi.
- **Storage:** barcha yuklangan fayllar (`attachments.storage_path`) yangi joylashuvga ko'chiriladi, yo'llar qayta xaritalanadi.
- **Flutter klient:** `services/supabase/` qatlamidagi barcha kod (`SupabaseService`, datasource'lar) almashtiriladi — bu Clean Architecture tufayli **faqat `data/` qatlamiga cheklanadi** (`domain`/`presentation` tegilmaydi), bu joriy arxitektura tanlovining to'g'ri ekanligini tasdiqlaydi.
- Bu "big bang" migratsiya bo'lib, rejalashtirilgan downtime yoki uzoq parallel-run davri talab qilishi mumkin.

## Xavfsizlik ta'siri

Joriy xavfsizlik modeli (RLS, service-role chegarasi, immutable audit) o'zi mustahkam — bu ADR xavfsizlik SIFATINI emas, balki ma'lumotning **jismoniy joylashuvi**ni ko'rib chiqadi. Agar migratsiya qilinsa, yangi platformada bir xil xavfsizlik kafolatlarini (RLS ekvivalenti yoki tenglashtiruvchi middleware) qayta tasdiqlash zarur bo'ladi — bu o'z-o'zidan to'liq xavfsizlik auditini talab qiladigan alohida ish hisoblanadi.

## Huquqiy/muvofiqlik ta'siri

Bu ADR'ning markazi. Muvofiq bo'lmaslikning potentsial oqibatlari: xizmatni cheklash/bloklash, ma'muriy jarima, litsenziya/ro'yxatdan o'tish talablari, va davlat organlari bilan ishlaydigan platforma sifatida obro'-e'tibor zarari. Bu masalada Claude Code **yakuniy huquqiy xulosa bera olmaydi** — faqat texnik xavfni belgilab, mustaqil huquqiy tekshiruv zarurligini ta'kidlaydi.

## Xarajat ta'siri

- **Status-quo (A):** qo'shimcha xarajat yo'q, lekin "yashirin qarz" — kelajakdagi majburiy migratsiya narxi ma'lum emas va nazoratsiz o'sadi.
- **Variant B/C/D:** mustaqil infratuzilmani boshqarish odatda Supabase'ning oylik boshqariladigan xizmat narxidan ko'ra ko'proq (DevOps xodimi vaqti, monitoring vositalari, backup infratuzilmasi, xavfsizlik yamoqlari) umumiy egalik narxini (TCO) talab qiladi — bu miqdoriy taqqoslash faqat variant tanlangandan keyin aniq byudjetlash bilan qilinishi mumkin.

## Yakuniy tavsiya

**Kod yoki migratsiya HOZIR o'zgartirilmaydi.** Birinchi va yagona darhol qadam — O'zbekiston shaxsiy ma'lumotlar qonunchiligi bo'yicha rasmiy huquqiy maslahat olish, Phase 6 boshlanishidan oldin. Bu ADR huquqiy javob kelgach "Qabul qilingan" holatiga o'tkazilib, tanlangan variant asosida yangilanishi kerak.

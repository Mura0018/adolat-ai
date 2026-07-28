# ADR-006: Hybrid Infrastructure Strategy — Sensitive Data Boundary va Vendor Mustaqilligi

**Status:** Qabul qilingan (2026-07-28) — loyiha egasi tomonidan to'g'ridan-to'g'ri berilgan arxitektura qarori (Claude Code tavsiyasi emas, quyidagi bo'limlar shu qarorni hujjatlashtiradi va amalga oshirish rejasini belgilaydi).

**Darajasi:** High (Phase 6'ning boshlang'ich arxitektura qarori)

**Bog'liq hujjatlar:** [`ADR-001`](./ADR-001-data-residency.md) (Bloklangan — **bu ADR uni almashtirmaydi va yopmaydi**), `docs/ARCHITECTURE.md`, `docs/DATABASE.md`

---

## Problem

`ADR-001` O'zbekiston shaxsiy ma'lumotlar qonunchiligi va Supabase (xorijiy hosting) o'rtasidagi muvofiqlik savolini ko'targan, lekin bu savol tashqi huquqiy tekshiruvga bog'liq va **hali ochiq** (`Bloklangan`). Phase 6 boshlanishi bilan, muhandislik ishi bu huquqiy javobni cheksiz kutib o'tira olmaydi — lekin shu bilan birga, huquqiy javob qanday bo'lishidan qat'i nazar keyinchalik qimmat qayta yozishga olib keladigan qarorlar ham qabul qilinmasligi kerak.

Loyiha egasi bu tande muvozanatni saqlovchi oraliq (interim) arxitektura strategiyasini belgiladi: sezgir shaxsiy ma'lumotlar ishlab chiqarishda O'zbekiston hududidagi infratuzilmada joylashishga **loyihalanadi** (hozir emas — kelajakda), umumiy xizmatlar rivojlantirish paytida Supabase'da qolishi **mumkin**, va butun kod bazasi qaysi backend ishlatilishidan qat'i nazar minimal o'zgarish bilan migratsiya qilina oladigan tarzda qurilishi **shart**.

## Nima uchun muhim

- ADR-001 hal bo'lishini kutib, Phase 6'ni butunlay to'xtatib qo'yish amaliy emas — lekin ADR-001'siz "hammasi Supabase'da qoladi" deb faraz qilib davom etish ham ADR-001 salbiy javob bilan yopilganda katta qayta yozishga olib kelishi mumkin (`ADR-001`, "Uzoq muddatli ta'sir" bo'limida aynan shu xavf tasvirlangan).
- Bu ADR ikkala xavfni ham kamaytiradi: **hozir** hech qanday backend migratsiyasi qilinmaydi (ADR-001 hali javobsiz bo'lgani uchun buni qilish erta va noaniq bo'lardi), lekin kod bazasi **kelajakda** ADR-001 qaysi tomonga hal bo'lsa ham (Supabase muvofiq / faqat sezgir ma'lumot ko'chiriladi / hammasi ko'chiriladi) arzon moslasha oladigan qilib quriladi.
- Loyihaning mavjud Clean Architecture konventsiyasi (`docs/ARCHITECTURE.md`, "Ichki Kod Arxitekturasi") bu talabni deyarli qondiradi — bu ADR uni **rasmiy, majburiy qoidaga** aylantiradi va qamrovni aniq belgilaydi (qaysi ma'lumot "sezgir", qaysi emas).

## Sezgir ma'lumotlar tasnifi (Sensitive Data Classification)

Loyiha egasi tomonidan belgilangan sezgir toifalar va ularning joriy sxemadagi holati:

| Toifa | Joriy sxemada mavjudmi? | Joylashuvi (agar mavjud bo'lsa) |
|---|---|---|
| Pasport ma'lumotlari | **Yo'q** — hali qo'shilmagan | — |
| PINFL/JShShIR | **Yo'q** — hali qo'shilmagan | — |
| Telefon raqami | Ha | `profiles.phone_number` |
| Yuklangan huquqiy hujjatlar (dalil) | Ha | `attachments.*` (metadata) + Supabase Storage (haqiqiy fayl) |
| Manzil | Qisman — faqat tashkilot yuridik manzili | `organization_profiles.legal_address` (shaxsiy/uy manzili hali yo'q) |

**Muhim aniqlik:** pasport va PINFL/JShShIR kabi maydonlar **hozircha sxemada umuman mavjud emas**. Bu ADR ularning qanday saqlanishini o'zgartirmaydi (ular yo'q) — balki ular kelajakda qo'shilganda (masalan davlat identifikatsiya integratsiyasi uchun) shu ADR'da belgilangan sezgir-ma'lumot chegarasiga muvofiq loyihalanishi **shart** ekanligini oldindan belgilaydi, keyinroq retrofit qilish o'rniga.

**Hal qilinmagan chekka holat (ochiq qoldirilgan, keyingi ADR yoki mahsulot qarori talab qiladi):** `appeals.body_text`, `disputes.description`/`respondent_statement` kabi erkin matn maydonlari — bular struktura jihatidan "sezgir ustun" emas, lekin foydalanuvchi bu matn ichiga tasodifan pasport raqami yoki PINFL kabi ma'lumot kiritishi mumkin. Ustun darajasidagi tasnif bunday holatni qamrab olmaydi. Bu ADR bu muammoni **hal qilmaydi** — faqat mavjudligini qayd etadi, chunki hal qilish (masalan kontent skanerlash yoki UI ogohlantirishi) alohida mahsulot/huquqiy qaror talab qiladi.

## Ko'rib chiqilgan variantlar

**A. Status-quo — ADR-001 hal bo'lguncha hech narsa o'zgarmaydi, Phase 6 to'xtaydi**
- ➖ Loyiha egasi tomonidan rad etildi — "Phase 6 begins now" ko'rsatmasi bilan mos emas.

**B. To'liq gibrid — hoziroq O'zbekiston hududida real infratuzilma o'rnatiladi, sezgir jadvallar darhol ko'chiriladi**
- ➖ Loyiha egasi tomonidan so'ralmagan — ko'rsatmada aniq "sensitive... must be **designed** to reside" (hozir emas, kelajak holati) va "may continue using Supabase **during development**" deyilgan. Bundan tashqari, ADR-001 hali hal qilinmagan holda real infratuzilma tanlash (qaysi provayder, qaysi hudud) asossiz bo'lardi.

**C. Dizayn bo'yicha gibrid, amalda yagona backend (tanlangan variant) — barcha ma'lumot (sezgir va umumiy) hozircha Supabase'da qoladi, lekin HAR BIR ma'lumot kirish yo'li repository interfeysi orqali o'tadi, `domain`/`presentation` qatlamlari Supabase'ga umuman bog'liq bo'lmaydi**
- ➕ Loyiha egasining aniq ko'rsatmasiga to'g'ridan-to'g'ri mos: "keep the architecture vendor-independent... all data access must go through repositories/interfaces."
- ➕ Mavjud Clean Architecture konventsiyasiga tabiiy mos keladi — hozir qo'shimcha murakkablik yaratmaydi, faqat mavjud naqshni majburiy qiladi.
- ➕ Tekshirildi: hozirgi 5 ta feature'ning birontasida ham `domain`/`presentation` qatlamida `package:supabase_flutter` importi yo'q — bu qoida allaqachon amalda bajarilgan, endi rasman mustahkamlanadi.
- ➖ ADR-001 hal bo'lmaguncha, "sezgir ma'lumot O'zbekistonda" degan yakuniy holat hali **haqiqiy emas** — faqat shunga tayyor infratuzilma (repository chegarasi) mavjud. Bu holat aniq belgilanishi kerak (quyida).

**D. Ikkita backend'ni hozirdan parallel ishlatish (masalan sezgir ma'lumot uchun mahalliy Postgres, umumiy uchun Supabase)**
- ➖ Rad etildi — ADR-001 hal bo'lmasdan bu tanlovni real infratuzilma bilan amalga oshirish erta; bundan tashqari ADR-001'ning o'zi bu variantni ("D. Gibrid") allaqachon ko'rib chiqqan va "eng murakkab, eng xato-moyil" deb baholagan.

## Tavsiya etilgan qaror

**Variant C** — quyidagi majburiy qoidalar bilan:

1. **Repository chegarasi — istisnosiz:** `lib/features/<nom>/domain/` va `lib/features/<nom>/presentation/` ostidagi hech qanday fayl `package:supabase_flutter` yoki boshqa backend-maxsus paketni to'g'ridan-to'g'ri import qilmaydi. Faqat `data/datasources/` va `services/supabase/` bunga ruxsat etilgan yagona joy. Bu qoida `docs/ARCHITECTURE.md`ga rasman kiritiladi (pastga qarang) va kelajakda kod review'da tekshiriladi.
2. **Sezgir ma'lumot uchun qo'shimcha ehtiyotkorlik:** yuqoridagi jadvaldagi sezgir ustunlarga (`profiles.phone_number`, `attachments.*`, kelajakdagi pasport/PINFL/manzil maydonlari) kirish har doim **aynan bitta** repository metodi orqali bo'ladi — bevosita SQL/Supabase so'rovi domain/presentation qatlamidan chaqirilmaydi (bu allaqachon 1-qoida bilan qoplangan, lekin sezgir ma'lumot uchun alohida ta'kidlanadi).
3. **Hozirgi holat aniq belgilanadi:** joriy bosqichda (Phase 6, ADR-001 hali ochiq) barcha ma'lumot, jumladan sezgir toifalar, **hamon Supabase'da** saqlanadi — bu ADR buni o'zgartirmaydi. O'zgargan narsa — bu holat endi ataylab, vaqtinchalik va **kuzatiladigan** (bu ADR orqali hujjatlashtirilgan), tasodifiy va yashirin emas.
4. **Migratsiya tetiklovchisi:** sezgir ma'lumotni haqiqatan O'zbekiston infratuzilmasiga ko'chirish qarori faqat ADR-001 hal bo'lgandan keyin (yoki loyiha egasi alohida buyruq bergandan keyin) boshlanadi — bu ADR bunday migratsiyani hozir BOSHLAMAYDI, faqat uni **arzon** qiladi.

## Uzoq muddatli ta'sir

Repository chegarasini hozir qat'iy talab sifatida mustahkamlash — har bir yangi feature (auth, keyinchalik boshqalar) shu qoidaga ongli ravishda qurilishini ta'minlaydi, bu esa ADR-001 istalgan tomonga hal bo'lganda migratsiya narxini `docs/ARCHITECTURE.md`da allaqachon ta'kidlangan darajada ("faqat `data/` qatlami o'zgaradi") ushlab turadi. Aksincha, bu qoidani norasmiy/tekshirilmagan holda qoldirish — vaqt o'tishi bilan qulaylik uchun `domain`/`presentation`ga Supabase-maxsus kod sizib chiqishi xavfini oshiradi (masalan `PostgrestException`ni to'g'ridan-to'g'ri UI qatlamida ushlash kabi).

## Migratsiya ta'siri

Hozir **hech qanday ma'lumotlar bazasi migratsiyasi yoki ma'lumot ko'chirish yo'q**. Ta'sir faqat kod arxitekturasi darajasida: yangi qurilayotgan `auth` feature'i (Module 1, quyida) boshidanoq shu qoidaga muvofiq quriladi. Mavjud 5 ta feature allaqachon muvofiq (tekshirildi, o'zgarish talab qilinmaydi).

## Xavfsizlik ta'siri

To'g'ridan-to'g'ri ta'sir yo'q — RLS, service-role chegarasi va boshqa xavfsizlik mexanizmlari o'zgarmaydi. Bilvosita foyda: repository chegarasi qat'iy bo'lganda, kelajakdagi xavfsizlik auditi (masalan "qaysi kod sezgir ustunlarga kira oladi") ancha osonlashadi — kirish nuqtalari soni cheklangan va nazorat qilinadigan bo'lib qoladi.

## Huquqiy/muvofiqlik ta'siri

Bu ADR ADR-001'ning huquqiy savolini **hal qilmaydi va yopmaydi** — u hamon `Bloklangan`, tashqi huquqiy tekshiruvni kutmoqda. Bu ADR faqat muhandislik tayyorgarligini ta'minlaydi, shunda huquqiy javob kelganda harakat tezkor va arzon bo'ladi. Agar kimdir bu ADR'ni "muvofiqlik muammosi hal qilindi" deb noto'g'ri talqin qilsa — bu **noto'g'ri**: hozirgi holatda sezgir ma'lumot hamon xorijiy hostingda (Supabase), faqat kelajakda ko'chirish tayyorgarligi ko'rilgan.

## Xarajat ta'siri

Minimal — repository chegarasi allaqachon amalda mavjud (tekshirildi), shuning uchun bu qarorning o'zi qo'shimcha ish talab qilmaydi, faqat kelajakdagi feature'lar shu qoidaga rioya qilishini talab qiladi. Kelajakdagi haqiqiy infratuzilma migratsiyasi xarajati (agar ADR-001 buni talab qilsa) `ADR-001`da allaqachon tahlil qilingan.

## Yakuniy tavsiya

Variant C rasman qabul qilingan va amal qiladi. `docs/ARCHITECTURE.md`ga repository-chegara qoidasi va sezgir ma'lumot tasnifi rasman kiritiladi (shu commit doirasida). Phase 6'ning birinchi implementatsiya moduli (auth feature) shu ADR'ga to'liq muvofiq quriladi — bu yangi qoidaning birinchi jonli sinovi bo'ladi.

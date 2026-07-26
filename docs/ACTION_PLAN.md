# ACTION_PLAN.md — Adolat AI audit topilmalari harakat rejasi

Bu hujjat **faqat qayta ishlatiladigan shablon (template) hujjati** — hozircha aniq loyiha topilmasi yozilmagan, faqat tuzilma va qoidalar belgilangan.

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

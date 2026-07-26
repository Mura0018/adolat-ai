# IDEA_PARKING.md — Adolat AI kelgusi g'oyalar arxivi

Bu hujjat **faqat qayta ishlatiladigan shablon (template) hujjati** — hozircha aniq loyiha g'oyasi yozilmagan, faqat tuzilma va qoidalar belgilangan.

## Purpose

- MVP chegarasidan tashqarida qolgan, lekin butunlay yo'qotib yubormaslik kerak bo'lgan g'oyalarni saqlash uchun markaziy joy (`docs/DEVELOPMENT_RULES.md`, 8-band: "MVP chegarasidan tashqaridagi barcha g'oyalar IDEA_PARKING.md ga yoziladi").
- Maqsad — **doirani kengaytirishdan himoya qilish**: bironta g'oya "keyinroq kerak bo'lishi mumkin" degan sabab bilan hozirgi MVP hujjatlariga (`docs/DATABASE.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md` va h.k.) qo'shilib, ularni og'irlashtirmasligi kerak — bunday g'oya shu yerga yoziladi va asosiy hujjatlar toza qoladi.
- Ayni paytda, g'oya butunlay unutilmasligi kerak — shu sababli "rad etish" o'rniga "parkovka qilish" (keyinroq qayta ko'rib chiqish uchun saqlash) tamoyili qo'llanadi.
- Bu yerga yozilgan g'oyalar **avtomatik ravishda kelajakdagi majburiyat emas** — ular faqat kelgusida qayta ko'rib chiqilishi mumkin bo'lgan nomzodlar ro'yxati.

## Rules for parking future ideas

- Har qanday g'oya, agar u joriy MVP chegarasidan (`docs/DATABASE.md`, "MVP doirasi bo'yicha qabul qilingan qarorlar" bo'limi; `docs/ROADMAP.md`, "MVP Scope" bo'limi) tashqarida bo'lsa, shu yerga yoziladi — muhokama davomida yoki kod/hujjat yozish jarayonida paydo bo'lgan har qanday "buni ham qo'shsak yaxshi bo'lardi" fikri shu qoidaga bo'ysunadi.
- G'oya yozilganda, uni keyinroq tushunish uchun yetarli kontekst berilishi shart: g'oya nima, nega hozir MVP'ga kiritilmagan, qaysi hujjat/muhokama uni keltirib chiqargan.
- G'oya hech qachon shunchaki o'chirilmaydi — agar u endi kerak emas deb topilsa, holati (status) "Rad etilgan" ("Bekor qilingan") deb belgilanadi, lekin yozuv tarixiy iz sifatida saqlanib qoladi.
- G'oya MVP'ga kiritilishi kerak deb qaror qilinsa, u tegishli asosiy hujjatga (`docs/DATABASE.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md` va h.k.) ko'chiriladi va shu yerdagi yozuv holati "MVP'ga qabul qilindi" deb yangilanadi — ikkalasida ham bir xil g'oya faol holda ikki marta yuritilmaydi.
- Bu hujjat davriy ravishda (masalan har bir Bosqich/Phase yakunida, `docs/ROADMAP.md`ga muvofiq) ko'rib chiqilishi tavsiya etiladi — bu g'oyalar butunlay unutilib ketmasligini ta'minlaydi.
- Har bir yozuv mustaqil va o'z-o'zidan tushunarli bo'lishi kerak — boshqa yozuvga yoki tashqi muhokamaga (masalan chat tarixi) ishora qilib, o'sha kontekstsiz tushunarsiz bo'ladigan yozuv yozilmaydi.

## Priority levels

G'oyaning **shoshilinchligi emas**, balki kelgusida qayta ko'rib chiqishga qanchalik loyiqligini bildiruvchi darajalar:

- **Yuqori (High):** g'oya foydalanuvchi yoki loyiha uchun sezilarli qiymat qo'shishi mumkin, keyingi yirik bosqich rejalashtirilganda birinchi navbatda ko'rib chiqilishi tavsiya etiladi.
- **O'rta (Medium):** foydali bo'lishi mumkin, lekin shoshilinch emas — muntazam ko'rib chiqishda baholanadi.
- **Past (Low):** kichik yaxshilanish yoki niche stsenariy — faqat resurs bo'sh bo'lganda ko'rib chiqiladi.

## Status tracking

Har bir g'oya quyidagi holatlardan birida bo'ladi:

- **Yangi (New):** hali ko'rib chiqilmagan, endigina qo'shilgan.
- **Ko'rib chiqilmoqda (Under Review):** muhokama qilinmoqda, lekin hali qaror qabul qilinmagan.
- **MVP'ga qabul qilindi (Accepted into Roadmap):** tegishli asosiy hujjatga (`docs/ROADMAP.md` va h.k.) ko'chirilgan; bu yerdagi yozuv endi faqat tarixiy iz.
- **Kechiktirildi (Deferred):** ko'rib chiqilgan, lekin hozircha kiritilmaydi deb qaror qilingan — kelgusida qayta ko'rib chiqiladi.
- **Bekor qilindi (Rejected):** loyiha yo'nalishiga mos emas deb topilgan; yozuv o'chirilmaydi, faqat shu holatga o'tkaziladi.

## Empty template for future ideas

Yangi g'oya qo'shishda quyidagi shablondan nusxa olib to'ldiring:

```
### [G'oya nomi]

- **Sana qo'shilgan:**
- **Taklif qilgan:**
- **Tavsif:**
- **Nega hozircha MVP tashqarisida:**
- **Bog'liq hujjat/muhokama:**
- **Ustuvorlik darajasi:** (Yuqori / O'rta / Past)
- **Holati:** (Yangi / Ko'rib chiqilmoqda / MVP'ga qabul qilindi / Kechiktirildi / Bekor qilindi)
- **Izohlar:**
```

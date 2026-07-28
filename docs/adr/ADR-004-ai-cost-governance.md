# ADR-004: AI xarajatini boshqarish va suiiste'moldan himoya

**Status:** Taklif qilingan

**Darajasi:** High (Zero-Regret Audit, High topilma #6)

**Bog'liq hujjatlar:** `docs/SECURITY.md` ("Rate Limiting" bo'limi — AI so'rovlari uchun cheklov "ko'rib chiqiladi" deb yozilgan, lekin aniq son/mexanizm belgilanmagan), `docs/ARCHITECTURE.md` ("AI Service" bo'limi)

---

## Problem

AI Service hali amalga oshirilmagan (faqat arxitektura darajasida tavsiflangan), lekin uning xarajat modeli va suiiste'moldan himoyasi hali **loyihalashtirilmagan**. Hozirgi hujjatlarda:
- Foydalanuvchi/kunlik AI so'rov soniga aniq chegara yo'q.
- Umumiy xarajat byudjeti yoki uni kuzatish mexanizmi yo'q.
- Bir xil yoki juda o'xshash kirish ma'lumoti uchun AI natijasini keshlash/qayta ishlatish strategiyasi yo'q.
- Foydalanuvchi ataylab yoki tasodifan (masalan ilovadagi xato tufayli) ko'p sonli murojaat/nizo yaratib, har birida AI tahlilini ishga tushirishi mumkin — bu holatda nima bo'lishi aniqlanmagan.

## Nima uchun muhim

- Ko'pchilik SaaS mahsulotlarida infratuzilma xarajati foydalanuvchi soniga nisbatan sublinear o'sadi (masshtab iqtisodi). AI inference xarajati bunga **teskari** — deyarli chiziqli yoki undan yomonroq (agar suiiste'mol qilinsa) o'sadi, chunki har bir so'rov haqiqiy hisoblash (va odatda tashqi API) xarajatini keltirib chiqaradi.
- AI — bu mahsulotning **eng qimmat** doimiy operatsion xarajat moddasi bo'lishi ehtimoli yuqori (Storage yoki DB xarajatidan farqli o'laroq, bu allaqachon fayl hajmi/turi cheklovlari orqali qisman nazorat qilinadi).
- 1 million foydalanuvchida, hatto kichik foizli suiiste'mol (masalan 0.1% foydalanuvchi skript orqali spam so'rov yuborsa) ham mutlaq sonlarda katta xarajatga aylanishi mumkin.
- Bu — **texnik qarz emas, balki loyihalash bo'shlig'i**: AI Service hali qurilmagani uchun, xarajat nazoratini boshidanoq loyihalash keyinchalik "tez-tez foydalanuvchi shikoyat qilgandan keyin" qo'shishdan ancha arzon.

## Ko'rib chiqilgan variantlar

**A. Status-quo — hech qanday chegara, faqat umumiy Supabase loyihasi darajasidagi standart so'rov cheklovi**
- ➕ Eng sodda, MVP tezligiga xalaqit bermaydi.
- ➖ Xarajat nazoratsiz o'sishi mumkin; bitta buzilgan client yoki avtomatlashtirilgan skript butun oylik byudjetni bir necha soatda "yeyishi" mumkin.

**B. Foydalanuvchi darajasidagi statik chegara — masalan kuniga N ta AI tahlil so'rovi (murojaat/nizo bo'yicha) foydalanuvchi boshiga**
- ➕ Sodda amalga oshirish (foydalanuvchi + sana bo'yicha hisoblagich, `ai_analyses` yozuvlari orqali yoki alohida hisoblagich jadvali orqali tekshirish mumkin).
- ➖ Haqiqiy, faol foydalanuvchini (masalan bir nechta haqiqiy nizo bilan shug'ullanayotgan tashkilot) noo'rin cheklashi mumkin, agar chegara juda past qo'yilsa; global xarajat portlashidan to'liq himoya qilmaydi (ko'p sonli yangi hisob ochilsa).

**C. Global xarajat byudjeti asosidagi "circuit breaker" — kunlik/oylik umumiy AI xarajati oldindan belgilangan chegaraga yetganda, yangi so'rovlar **rad etilmaydi**, balki navbatga qo'yiladi va keyinroq (masalan ertasi kuni byudjet yangilanganda) qayta ishlanadi**
- ➕ Global xarajatni qat'iy nazorat qiladi — "hech qachon byudjetdan oshmaslik" kafolati.
- ➕ "No Dead End Rule" (`DEVELOPMENT_RULES.md`, 17-band) bilan mos — foydalanuvchi rad etilmaydi, faqat kutadi, va bu holat aniq ko'rsatiladi.
- ➖ Yolg'iz holda foydalanuvchi darajasidagi suiiste'molni oldini olmaydi (bitta foydalanuvchi butun byudjetni tugatishi mumkin, boshqalar navbatda qoladi).

**D. B + C birgalikda — foydalanuvchi darajasidagi chegara (suiiste'molni cheklaydi) + global byudjet circuit breaker (umumiy xarajatni cheklaydi)**
- ➕ Ikkala xavfdan (individual suiiste'mol va umumiy xarajat portlashi) himoyalanadi.
- ➖ Eng ko'p loyihalash/amalga oshirish ishi (ikkita mustaqil mexanizm, ikkalasi ham monitoring bilan kuzatilishi kerak).

## Afzallik va kamchiliklar (qisqa xulosa)

| Variant | Individual suiiste'moldan himoya | Global xarajat nazorati | Amalga oshirish murakkabligi |
|---|---|---|---|
| A — Status-quo | Yo'q | Yo'q | Yo'q |
| B — Foydalanuvchi chegarasi | Ha | Qisman | Past |
| C — Global byudjet | Yo'q | Ha | O'rta |
| D — B + C | Ha | Ha | O'rta-yuqori |

## Tavsiya etilgan qaror

**Variant D (foydalanuvchi chegarasi + global byudjet circuit breaker)** — ikkalasi ham nisbatan sodda mexanizmlar bo'lib, birgalikda to'liqroq himoya beradi:

1. **Foydalanuvchi chegarasi:** kuniga foydalanuvchi boshiga maksimal AI tahlil so'rovi soni (aniq son — mahsulot jamoasi bilan kelishilishi kerak, masalan real foydalanuvchi ehtiyojidan 3–5 baravar yuqori qilib boshlanadi, keyin monitoring asosida moslashtiriladi).
2. **Global byudjet:** kunlik/oylik AI xarajati uchun aniq pul chegarasi va monitoring ogohlantirishi (`docs/SECURITY.md`, "Monitoring" bo'limidagi umumiy tamoyilga muvofiq); chegaraga yaqinlashganda ogohlantirish, yetganda yangi so'rovlar navbatga qo'yiladi.
3. Ikkala holatda ham foydalanuvchiga aniq va tushunarli xabar ko'rsatiladi ("Kunlik so'rov chegarasiga yetdingiz, ertaga qayta urinib ko'ring" / "Tizim hozir band, so'rovingiz navbatga qo'yildi") — "No Dead End Rule"ga muvofiq.

## Uzoq muddatli ta'sir

Bu mexanizmlarni AI Service bilan **bir vaqtda** loyihalash — keyinroq (foydalanuvchi bazasi va xarajat naqshlari allaqachon shakllangandan keyin) qo'shishdan ancha arzon. Kechiktirilgan holda, chegara qo'yish mavjud foydalanuvchi xatti-harakatini "buzadi" (masalan avval cheksiz bo'lgan narsa to'satdan cheklanadi) — bu UX regressiyasi sifatida qabul qilinishi mumkin, boshidanoq mavjud bo'lgan chegaradan farqli o'laroq.

## Migratsiya ta'siri

AI Service hali qurilmagani uchun, bu — **yangi funksionallik ustiga qo'shiladigan** dizayn talabi, mavjud migratsiyalarga ta'sir qilmaydi. Amalga oshirilganda kerak bo'ladigan narsa: foydalanuvchi/kunlik hisoblagich uchun kichik jadval yoki mavjud `ai_analyses.created_at` + `case_type` orqali hisoblash so'rovi (indekslangan), va global byudjet holatini saqlovchi bitta konfiguratsiya/holat yozuvi.

## Xavfsizlik ta'siri

Bu — ham xavfsizlik, ham operatsion masala: cheklanmagan AI so'rovlari nafaqat xarajat, balki potentsial denial-of-service (boshqa foydalanuvchilar uchun navbat cho'zilishi) vektori hamdir. `docs/SECURITY.md`ning "Rate Limiting" bo'limi buni allaqachon tan olgan, lekin aniq raqamlarsiz.

## Huquqiy/muvofiqlik ta'siri

To'g'ridan-to'g'ri huquqiy ta'sir yo'q, lekin bilvosita bog'liqlik bor: agar xarajat nazoratsizligi sababli AI Service to'xtatilsa yoki sifat pasaysa, bu foydalanuvchining davlat organiga murojaat yuborish huquqini amalga oshirish qobiliyatiga ta'sir qilishi mumkin — bu esa mahsulotning ijtimoiy vazifasiga (`docs/ROADMAP.md`, "Project Vision") zid.

## Xarajat ta'siri

Bu ADR bevosita **xarajatni tejash** haqida — investitsiya (loyihalash + kichik amalga oshirish ishi) o'zini tez qoplaydi, chunki nazoratsiz AI xarajati boshqaruvsiz o'sib ketishi mumkin bo'lgan yagona eng katta operatsion xarajat moddasi hisoblanadi.

## Yakuniy tavsiya

Variant D'ni AI Service dizaynining **ajralmas qismi** sifatida, Phase 3 boshlanishidan oldin aniq raqamlar bilan hujjatlashtirish (bu ADR'ning o'zi emas, balki AI Service texnik spetsifikatsiyasining bir qismi sifatida). AI Service kodi yozilishidan oldin bu chegaralar kelishilgan bo'lishi shart — keyinroq qo'shish emas, boshidanoq bo'lishi kerak.

# ADR-003: AI huquqiy iqtiboslari uchun qonun moddalari versiyalash

**Status:** Taklif qilingan

**Darajasi:** High (Zero-Regret Audit, High topilma #3)

**Bog'liq hujjatlar:** `docs/DATABASE.md` (9-jadval `laws`, 10-jadval `ai_analysis_law_references`, "Kelgusi bosqichlar uchun ataylab qoldirilgan" bo'limi), `docs/ARCHITECTURE.md` ("AI Service" bo'limi)

---

## Problem

`laws` jadvali O'zbekiston qonunchiligi moddalarining faqat **joriy holatini** saqlaydi (`code_name`, `article_number`, `summary_text`, `is_active`, `updated_at`). Modda tahrirlanganda (masalan qonun o'zgartirilganda), mavjud qator joyida yangilanadi (`UPDATE`) — eski matn hech qayerda saqlanmaydi.

`ai_analyses` — `ai_analysis_law_references` orqali `laws.id`ga iqtibos qiladi. Bu FK — moddaning **joriy** holatiga, moddaning **AI tahlil o'tkazilgan paytdagi** holatiga emas.

Natija: agar modda matni keyinchalik o'zgartirilsa, o'tmishdagi har qanday AI tahlili (`ai_analyses.analysis_text`, `legal_basis_summary`) hali ham o'sha `law_id`ga ishora qiladi, lekin endi bu ID ortidagi matn **boshqa** (yangilangan) matn — tahlil o'z vaqtida haqiqiy bo'lgan asosga endi mos kelmasligi mumkin, va bu holat hech qayerda ko'rsatilmaydi.

Bu allaqachon `docs/DATABASE.md`ning "Kelgusi bosqichlar uchun ataylab qoldirilgan" bo'limida tan olingan MVP cheklovi. Bu ADR uni **navbatdagi "g'oya"** emas, balki **vaqt darajasida cheklangan imkoniyat oynasi** sifatida qayta baholaydi.

## Nima uchun muhim

- Adolat AI'ning asosiy qadr-qiymati — "AI faqat qonun va faktlarga asoslanadi" (`DEVELOPMENT_RULES.md`, 15-band). Agar qonun asosi vaqt o'tishi bilan "suzib ketsa" (drift), bu qadr-qiymatning o'zi zaiflashadi — foydalanuvchi yoki keyinchalik tekshiruvchi (masalan admin yoki huquqshunos) tahlilni tasdiqlay olmaydi.
- Bu — **faqat kelajakka qarab tuzatiladigan** muammo emas: agar biror modda matni allaqachon ustidan yozilgan bo'lsa, o'sha eski matn **butunlay yo'qolgan** — uni keyinchalik qayta tiklab bo'lmaydi. Shu sababli bu topilma "keyinroq ham tuzatsak bo'ladi" toifasiga kirmaydi — har bir kechiktirilgan `UPDATE laws SET ...` amali potentsial ravishda tiklanmas ma'lumot yo'qotilishi hisoblanadi.
- 1 million foydalanuvchi va ko'p yillik AI tahlil tarixi bilan, bu masala tasodifiy emas — O'zbekiston qonunchiligi vaqti-vaqti bilan tahrirlanadi, demak bu **muqarrar ravishda** yuzaga keladi.

## Ko'rib chiqilgan variantlar

**A. Status-quo — `laws` joriy holatni saqlaydi, tarix yo'q**
- ➕ Eng sodda, hozirgi holat.
- ➖ Yuqorida tavsiflangan tiklanmas ma'lumot yo'qotish xavfi davom etadi.

**B. Append-only versiyalash — har bir tahrirda `laws`ga yangi qator qo'shiladi (eski qator o'zgarmaydi), `effective_from`/`effective_to` ustunlari bilan; `laws.id` endi "modda versiyasi identifikatori"; alohida "modda" tushunchasi (`code_name` + `article_number` kombinatsiyasi) barqaror qoladi**
- ➕ `laws` jadvalining mavjud tuzilmasiga eng yaqin — minimal kontseptual o'zgarish (ustun qo'shish + `UPDATE` o'rniga `INSERT` odatini o'zgartirish).
- ➖ "Joriy moddani ko'rsat" so'rovlari endi `WHERE code_name=... AND article_number=... ORDER BY effective_from DESC LIMIT 1` kabi murakkablashadi (yoki alohida view kerak bo'ladi); mavjud composite unique index (`code_name`, `article_number`) endi unique bo'lmaydi, qayta loyihalanishi kerak.

**C. Alohida `law_versions` jadvali — `laws` "modda" identifikatorini (barqaror, o'zgarmas) ifodalaydi, `law_versions` esa har bir tahrirni alohida qator sifatida saqlaydi (`law_id` FK, `effective_from`/`effective_to`, `summary_text`); `ai_analysis_law_references` endi `law_id`ga emas, `law_version_id`ga bog'lanadi**
- ➕ Eng toza normalizatsiya — "modda" va "moddaning muayyan holati" tushunchalari aniq ajratilgan; mavjud `laws.id` semantikasi (barqaror modda identifikatori) o'zgarmaydi, faqat matn qayerdan olinishi o'zgaradi; kelajakda "joriy holatni ko'rsat" so'rovi oddiy (`law_versions WHERE law_id=... AND effective_to IS NULL`).
- ➖ Yangi jadval + FK yo'nalishini o'zgartirish (`ai_analysis_law_references.law_id` → `law_version_id`) — mavjud sxemaga (hozircha bo'sh, real ma'lumot yo'q, shuning uchun bu bosqichda arzon) o'zgarish.

**D. Versiyalashsiz, lekin AI tahlili paytida matnni to'liq "muzlatib" nusxa ko'chirish — `ai_analyses` yoki bog'lovchi jadvalga moddaning o'sha paytdagi to'liq matnini saqlash, `laws.id`ga alohida versiyalash qo'shmasdan**
- ➕ Eng kam sxema o'zgarishi — `laws` umuman o'zgarmaydi.
- ➖ Ma'lumot ortiqchaligi (denormalizatsiya) — bir xil matn ko'p marta nusxalanadi; "bu modda hozir qanday o'zgargan" degan umumiy so'rovni qo'llab-quvvatlamaydi (faqat AI tahlili nuqtai nazaridan "muzlatilgan", modda tarixining o'zi hamon yo'qolgan holicha qoladi — masalan admin panelida "bu modda vaqt o'tishi bilan qanday o'zgargan" ko'rsatib bo'lmaydi).

## Afzallik va kamchiliklar (qisqa xulosa)

| Variant | Ma'lumot yo'qolishi oldini oladimi | Sxema murakkabligi | Mavjud so'rovlarga ta'sir |
|---|---|---|---|
| A — Status-quo | Yo'q | Eng past | Yo'q |
| B — Append-only `laws` | Ha | O'rta | Unique index qayta loyihalash kerak |
| C — Alohida `law_versions` | Ha | O'rta-yuqori | Yangi jadval, bitta FK yo'nalishi o'zgaradi |
| D — Snapshot AI tahlilida | Faqat AI konteksti uchun | Past | Yo'q, lekin modda tarixi o'zi saqlanmaydi |

## Tavsiya etilgan qaror

**Variant C (alohida `law_versions` jadvali)** — chunki:
1. `laws.id` semantikasi barqaror qoladi ("bu — Mehnat kodeksining 88-moddasi" degan tushuncha o'zgarmaydi), bu joriy kodning boshqa joylarida (agar bo'lsa) buzilishlarni oldini oladi.
2. "Modda qachon qanday bo'lgan" so'rovi (huquqiy tekshiruv/audit uchun muhim) tabiiy ravishda qo'llab-quvvatlanadi.
3. Hozirgi bosqichda `laws` jadvalida real ishlab chiqarish ma'lumoti yo'q (loyiha hali production'ga chiqmagan) — bu FK yo'nalishini o'zgartirish uchun **eng arzon oyna**, chunki hech qanday mavjud `ai_analysis_law_references` qatorini migratsiya qilish kerak emas.

## Uzoq muddatli ta'sir

Bu qarorni hozir (production ma'lumoti yo'q paytda) qabul qilish deyarli xarajatsiz. Agar bu Phase 3 (AI integratsiyasi) boshlanguncha kechiktirilsa, keyinroq qo'shish hali ham mumkin, lekin AI Service qurilib, real `ai_analyses`/`ai_analysis_law_references` qatorlari to'planganidan keyin FK yo'nalishini o'zgartirish endi **ma'lumotlarni ko'chirish** (backfill) talab qiladi — bu vaqt va xato xavfini oshiradi.

## Migratsiya ta'siri

Yangi migratsiya kerak bo'ladi: `law_versions` jadvali yaratish, `laws`dan mavjud (agar bo'lsa) ma'lumotni bitta boshlang'ich versiya sifatida ko'chirish, `ai_analysis_law_references.law_id` ustunini `law_version_id`ga o'zgartirish (yoki yangi ustun qo'shib eskisini bekor qilish), tegishli RLS siyosatlarini (`laws_select`, `laws_insert_admin` va h.k.) yangi jadvalga moslashtirish. Hozirgi bosqichda (real ma'lumot yo'q) bu — sof qo'shimcha migratsiya, mavjud 4 ta migratsiyaning birortasini o'zgartirishni talab qilmaydi.

## Xavfsizlik ta'siri

To'g'ridan-to'g'ri xavfsizlik ta'siri yo'q — bu ma'lumot yaxlitligi/to'g'riligi masalasi, kirish nazorati emas. `law_versions` uchun RLS `laws` bilan bir xil naqshni (public read, faqat admin yozadi) meros oladi.

## Huquqiy/muvofiqlik ta'siri

Bu ADR — Adolat AI'ning "AI faqat qonun va faktlarga asoslanadi" degan asosiy da'vosining ishonchliligini himoya qiladi. Agar kelajakda biror AI tahlili huquqiy nizoga sabab bo'lsa (masalan foydalanuvchi "AI noto'g'ri qonunga asoslandi" deb da'vo qilsa), tizim aynan o'sha paytdagi qonun matnini ko'rsata olishi kerak — versiyalashsiz bu **texnik jihatdan imkonsiz** bo'lib qoladi.

## Xarajat ta'siri

Minimal — bitta qo'shimcha jadval, saqlash hajmi nisbatan kichik (qonun matnlari sonli, versiyalar soni ham nisbatan kam bo'ladi, foydalanuvchi ma'lumoti bilan solishtirganda). Amalga oshirish vaqti kichik (bir necha soatlik migratsiya + repository qatlami moslashtirish), lekin AI Service qurilishidan OLDIN qilinishi shart bo'lgani uchun rejalashtirish tartibiga ta'sir qiladi.

## Yakuniy tavsiya

Variant C ni Phase 3 (AI integratsiyasi) boshlanishidan oldin, alohida kichik migratsiya sifatida amalga oshirish. Bu — ushbu beshta ADR orasida **eng past xavf, eng aniq yechimga ega** topilma; boshqa ADR'lardagi kabi tashqi (huquqiy) javobga bog'liq emas, shuning uchun tasdiqlangach darhol amalga oshirilishi mumkin.

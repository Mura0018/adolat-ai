# ADR-002: O'zgarmas audit jurnali vs ma'lumotni o'chirish (erasure) so'rovlari

**Status:** Qabul qilingan (2026-07-28) — dizayn qarori sifatida loyiha egasi tomonidan tasdiqlangan. **Eslatma:** bu faqat Variant B (pseudonymization) strategiyasining o'zi rasman qabul qilinganini bildiradi; amalga oshirish (SECURITY DEFINER funksiya yozish) hali qilinmagan — bu foydalanuvchi hisobini o'chirish feature'i rejalashtirilganda, alohida migratsiya sifatida bajariladi (pastdagi "Yakuniy tavsiya"ga qarang). Shuningdek, agar ADR-001'dagi huquqiy tekshiruv shaxsiy ma'lumotlarni o'chirish huquqi umuman talab qilinmasligini ko'rsatsa, bu ADR qayta ko'rib chiqilishi mumkin.

**Darajasi:** Critical (Zero-Regret Audit, Critical topilma #2)

**Bog'liq hujjatlar:** `docs/DATABASE.md` (7-jadval `case_status_history`, 13-jadval `audit_log`), `docs/SECURITY.md` ("Audit Log Security" bo'limi), `supabase/migrations/20260726000002_rls_policies.sql`

---

## Problem

`docs/DATABASE.md` va `docs/SECURITY.md`da ataylab va to'g'ri qaror qilingan: `case_status_history` va `audit_log` jadvallari uchun `UPDATE`/`DELETE` RLS siyosati **umuman berilmaydi** — hech kim, admin ham, mavjud yozuvni o'zgartira yoki o'chira olmaydi. Bu tamper-proof audit trail yaratish uchun to'g'ri va standart amaliyot.

Ammo har ikkala jadval ham foydalanuvchiga doimiy ishora saqlaydi:
- `case_status_history.changed_by` → `profiles.id` (nullable)
- `audit_log.actor_id` → `profiles.id` (nullable)

Agar foydalanuvchi kelajakda o'z shaxsiy ma'lumotlarini o'chirishni so'rasa (bu O'zbekiston qonunchiligida ham, umuman zamonaviy shaxsiy ma'lumotlar rejimlarida ham keng tarqalgan huquq — ADR-001'dagi huquqiy tekshiruv natijasiga qarab aniq ko'lami belgilanadi), hozirda bu so'rovni **immutability qoidasini buzmasdan qanoatlantirishning hujjatlashtirilgan yo'li yo'q**.

## Nima uchun muhim

- Bu ehtimoliy emas, balki huquqiy-tizim bilan ishlaydigan har qanday platforma uchun **kutilishi kerak bo'lgan** so'rov turi.
- Ikki talab bir-biriga zid ko'rinadi: audit yaxlitligi ("hech qachon o'zgartirilmaydi") va foydalanuvchi huquqi ("mening ma'lumotimni o'chiring") — lekin aslida ular to'g'ri loyihalashda **zid emas**, agar oldindan rejalashtirilsa.
- 1 million foydalanuvchi va yillar davomida to'plangan audit yozuvlari bilan, bu masalani **keyinroq** hal qilish minglab/millionlab qatorlarni tahlil qilib qayta ishlashni talab qiladi — hozir esa faqat kelgusi yozuvlar uchun mexanizm loyihalash kifoya.

## Ko'rib chiqilgan variantlar

**A. Status-quo — hech narsa qilinmaydi, masala kelajakda "qo'lda" hal qilinadi**
- ➕ Hech qanday ish talab qilmaydi hozir.
- ➖ Birinchi haqiqiy o'chirish so'rovi kelganda, jamoa bosim ostida shoshilinch qaror qabul qilishga majbur bo'ladi — bu odatda yomon dizaynga olib keladi.

**B. Pseudonymization (tavsiya etiladi) — foydalanuvchi hisobi o'chirilganda, `changed_by`/`actor_id` ustunlari `NULL` qilinadi (yozuvning o'zi butunligicha qoladi), maxsus service-role funksiya orqali**
- ➕ Audit yozuvining mazmuni (nima sodir bo'lgani, qachon) butunlay saqlanadi — audit maqsadi buzilmaydi.
- ➕ `changed_by`/`actor_id` allaqachon **nullable** qilib loyihalangan (`docs/DATABASE.md`da tasdiqlangan) — bu ustunlar aynan shu holat uchun ("tizim/AI bo'lsa null") emas, balki tasodifan mos kelib qoldi; muhimi, bu qiymatni keyinchalik `NULL`ga o'zgartirish **UPDATE emas**, balki maxsus, tor ko'lamli, faqat shu ustunlarga tegishli service-role operatsiyasi sifatida RLS'dan alohida yo'lda amalga oshirilishi mumkin (masalan alohida SECURITY DEFINER funksiya, umumiy UPDATE policy ochilmaydi).
- ➖ Audit trail "kim" qismini yo'qotadi — agar kelajakda xavfsizlik tekshiruvi aynan o'sha foydalanuvchi haqida savol bersa, javob endi yo'q (lekin bu — huquqning o'zi talab qiladigan tabiiy oqibat).

**C. Alohida "erasure_requests" jadvali + qo'lda admin ko'rib chiqish jarayoni, avtomatlashtirilmagan**
- ➕ Eng ehtiyotkor, eng kam avtomatik xavf — har bir so'rov inson tomonidan ko'rib chiqiladi.
- ➖ 1 million foydalanuvchi miqyosida qo'lda jarayon miqyoslanmaydi; javob berish vaqti (SLA) huquqiy talabga (agar muddat belgilangan bo'lsa) mos kelmasligi mumkin.

**D. audit_log/case_status_history'ni umuman shaxsga bog'lamaslik — faqat anonim/agregatlangan holat saqlash**
- ➕ Erasure muammosi umuman yo'qoladi.
- ➖ Audit jurnalining asosiy maqsadi ("kim, qachon, nima qildi") butunlay yo'qoladi — `docs/SECURITY.md`ning "Audit Log Security" talabiga ziddir, muvofiqlik/tergov maqsadida foydasiz bo'lib qoladi. Rad etiladi.

## Afzallik va kamchiliklar (qisqa xulosa)

| Variant | Audit yaxlitligi | Foydalanuvchi huquqi qondiriladimi | Miqyoslanuvchanlik |
|---|---|---|---|
| A — Status-quo | Saqlanadi | Yo'q | — |
| B — Pseudonymization | Saqlanadi | Ha (identifikator darajasida) | Yuqori (avtomatlashtirilishi mumkin) |
| C — Qo'lda jarayon | Saqlanadi | Ha (sekinroq) | Past |
| D — Anonimlashtirish | Yo'qoladi | Ha (ortiqcha) | Yuqori, lekin audit maqsadi yo'q |

## Tavsiya etilgan qaror

**Variant B (pseudonymization)** — quyidagi tuzilma bilan:

1. Foydalanuvchi hisobini o'chirish oqimi (hali qurilmagan, kelajakda "Profil sozlamalari" feature'ining bir qismi) service-role orqali ishlaydigan funksiyani chaqiradi.
2. Bu funksiya: (a) `profiles` yozuvini `auth.users` bilan bog'liq standart Supabase oqimi orqali o'chiradi/deaktivatsiya qiladi, (b) shu foydalanuvchiga tegishli barcha `case_status_history.changed_by` va `audit_log.actor_id` qiymatlarini `NULL`ga o'rnatadi — **faqat shu ikkita ustun**, qolgan barcha maydonlar (`action`, `entity_type`, `entity_id`, `to_status`, `created_at`) o'zgarishsiz qoladi.
3. Bu operatsiya RLS'dagi umumiy `UPDATE` siyosati orqali EMAS (immutability qoidasi buzilmaydi), balki alohida, faqat shu maqsad uchun yozilgan, keng ko'lamli UPDATE huquqi bermaydigan tor funksiya orqali amalga oshiriladi.

Bu ADR **hozircha faqat dizayn qarori** — amalga oshirish (funksiya yozish) foydalanuvchi hisobini o'chirish feature'i rejalashtirilganda, alohida migratsiya sifatida qilinadi.

## Uzoq muddatli ta'sir

Bu qarorni hozir (kod yozmasdan, faqat dizayn sifatida) qabul qilish kelajakda "hisobni o'chirish" feature'i qurilganda tayyor naqshga ega bo'lishni ta'minlaydi. Aksincha, buni kechiktirish — real o'chirish so'rovi kelganda tezkor, tekshirilmagan yechim yozishga bosim yaratadi, bu esa yoki audit yaxlitligini buzadigan (haqiqiy DELETE/UPDATE ochib yuborish) yoki foydalanuvchi huquqini qondirmaydigan xatoga olib kelishi mumkin.

## Migratsiya ta'siri

Hozircha **migratsiya kerak emas** — `changed_by`/`actor_id` ustunlari allaqachon nullable. Kelajakda kerak bo'ladigan yagona o'zgarish: bitta yangi SECURITY DEFINER funksiya (masalan `public.redact_actor_references(p_profile_id uuid)`), RLS siyosatlarining o'zi o'zgarmaydi. Bu kichik, izolyatsiyalangan migratsiya bo'ladi, mavjud 4 ta migratsiyaga ta'sir qilmaydi.

## Xavfsizlik ta'siri

Pseudonymization audit tizimining asosiy xavfsizlik xususiyatini (yozuvlar o'zgartirilmaydi/o'chirilmaydi) buzmaydi — faqat identifikator bog'lanishini uzadi. Bu funksiya albatta SECURITY DEFINER va faqat service-role orqali chaqiriladigan qilib loyihalanishi kerak (client to'g'ridan-to'g'ri chaqira olmasligi kerak), aks holda bu yangi zaifllik (foydalanuvchi boshqa birovning audit izini "yashirish" imkoniyati) yaratishi mumkin.

## Huquqiy/muvofiqlik ta'siri

Bu ADR ADR-001 bilan bevosita bog'liq: agar huquqiy tekshiruv shaxsiy ma'lumotlarni o'chirish huquqi majburiy emasligini ko'rsatsa, bu masalaning zarurati kamayadi (lekin yaxshi amaliyot sifatida saqlanishi tavsiya etiladi). Agar majburiy bo'lsa, bu — audit yaxlitligi va huquqiy majburiyat o'rtasidagi muvozanatni oldindan hal qiluvchi yagona to'g'ri yechim.

## Xarajat ta'siri

Minimal — bitta funksiya yozish va test qilish (bir martalik ish). Kelajakda "hisobni o'chirish" feature'i qurilganda, bu funksiya shu feature'ning tabiiy qismi bo'ladi, alohida katta loyiha emas.

## Yakuniy tavsiya

Pseudonymization strategiyasini (Variant B) rasman **dizayn qarori** sifatida qabul qilish — kod yozilmaydi, lekin kelajakdagi "hisobni o'chirish" feature'i shu naqshga muvofiq qurilishi rejalashtiriladi. ADR-001'dagi huquqiy javob kelgach, bu ADR shu javobga muvofiq qayta ko'rib chiqiladi (agar erasure huquqi umuman talab qilinmasa, ADR "Bekor qilingan, kuzatib boriladi" holatiga o'tkazilishi mumkin).

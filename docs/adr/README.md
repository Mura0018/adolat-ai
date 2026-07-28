# Architecture Decision Records (ADR) — Adolat AI

Bu papka **Zero-Regret Audit** (Phase 6'dan oldingi arxitektura auditi) davomida aniqlangan Critical va High darajadagi topilmalar bo'yicha rasmiy qarorlar hujjatini saqlaydi.

## Maqsad va qoida

- Har bir ADR — **faqat hujjat**, kod yoki SQL emas (`DEVELOPMENT_RULES.md`, 1–2-band: "Hujjatlarsiz kod yozilmaydi").
- ADR **qaror qabul qilingani haqida yozuv emas** — bu yerda "Tavsiya etilgan qaror" bo'limi muallifning (Claude Code) tahliliy tavsiyasi, **yakuniy tashkiliy qaror emas**. Ayniqsa ADR-001 va ADR-002 kabi huquqiy oqibatga ega qarorlar loyiha egasi/huquqshunos tomonidan rasman tasdiqlanishi shart.
- Status maydoni har bir ADR uchun joriy holatni ko'rsatadi: **Taklif qilingan** (hali tasdiqlanmagan) → **Qabul qilingan** (tasdiqlangan, amalga oshirilishi rejalashtirilgan) → **Amalga oshirilgan** (kod/migratsiya yozilgan) → **Bekor qilingan**.
- Phase 6 boshlanishidan oldin kamida ADR-001 va ADR-002 (Critical) **Qabul qilingan** holatiga o'tishi kerak — chunki ular loyihaning qolgan barcha texnik qarorlari (Supabase'ga bog'liqlik darajasi, RLS dizayni) uchun old shart hisoblanadi.

## Ro'yxat

| # | Sarlavha | Darajasi (Zero-Regret Audit) | Status |
|---|---|---|---|
| [ADR-001](./ADR-001-data-residency.md) | Data Residency — O'zbekiston shaxsiy ma'lumotlari qonuni vs Supabase hosting | Critical | Taklif qilingan |
| [ADR-002](./ADR-002-immutable-audit-vs-erasure.md) | O'zgarmas audit jurnali vs ma'lumotni o'chirish (erasure) so'rovlari | Critical | Taklif qilingan |
| [ADR-003](./ADR-003-law-versioning.md) | AI huquqiy iqtiboslari uchun qonun moddalari versiyalash | High | Taklif qilingan |
| [ADR-004](./ADR-004-ai-cost-governance.md) | AI xarajatini boshqarish va suiiste'moldan himoya | High | Taklif qilingan |
| [ADR-005](./ADR-005-ai-vendor-fallback.md) | AI vendor uzilishi/fallback strategiyasi | High/Medium | Taklif qilingan |

## Navbatdagi ADR'lar (hali yozilmagan)

Zero-Regret Audit'da aniqlangan qolgan High darajadagi topilmalar — foydalanuvchi ko'rsatmasiga muvofiq hozircha ushbu beshta ADR bilan cheklanadi, lekin quyidagilar keyingi navbatda ADR-006 dan boshlab hujjatlashtirilishi kerak:

- Offline-First arxitekturasi va Phase 2/3'da qurilgan repository shartnomalari (`Result<T>` qaytish turi) o'rtasidagi moslik masalasi.
- Ro'yxat (list) endpointlarida pagination yo'qligi (`listMine()` va h.k.).
- Yassi 3 rolli model (`citizen`/`organization`/`admin`) va operatsion miqyoslanish chegarasi.
- Avtomatlashtirilgan test va CI yo'qligi.

Bu ro'yxat `docs/ACTION_PLAN.md` bilan muvofiqlashtirilishi kerak (`DEVELOPMENT_RULES.md`, 25-band).

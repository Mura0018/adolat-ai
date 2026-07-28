# ai_service/ — AI Service Foundation (Module 4, Phase 1)

**Bu papka Flutter mobil ilovaning (`lib/`) bir qismi EMAS.**

## Nega alohida

`docs/ARCHITECTURE.md`, "AI Service" bo'limi: *"AI Service klient tomonidan to'g'ridan-to'g'ri chaqirilmaydi — faqat Supabase backend (service role) orqali ishga tushiriladi."* `docs/DATABASE.md`da `ai_analyses` jadvaliga yozish **faqat service role** orqali ruxsat etilgan — client to'g'ridan-to'g'ri yoza olmaydi. Bu qoida `DEVELOPMENT_RULES.md`, 15–16-bandlar (AI xolisligi) va `docs/adr/ADR-005-ai-vendor-fallback.md`ning tavsiyasi bilan ham mos.

Shu sababli bu kod:
- **hech qachon** `lib/` ichidagi hech bir fayl tomonidan import qilinmaydi;
- provayder API kalitlarini (OpenAI/Gemini/Claude) hech qachon o'zida saqlamaydi yoki mobil ilova binariga joylashtirmaydi;
- kelgusida **backend/serverless muhitda** (Supabase Edge Function yoki alohida Dart xizmati) joylashtirilishi mo'ljallangan.

## Nega shu repozitoriyada

`flutter analyze`/`flutter test` (loyihaning yagona sifat darvozasi — `.github/workflows/ci.yml`) shu papkani ham avtomatik tekshiradi, chunki u bir xil `pubspec.yaml` konteksti ostida yotadi. Bu — kod hali qayerda ishga tushishi (Edge Function/alohida xizmat) aniq belgilanmagan bosqichda ham, sifat nazoratini birinchi kundan boshlab ta'minlash uchun ataylab qilingan tanlov.

## Tuzilma

```
ai_service/
├── domain/          Sof Dart — interfeyslar va modellar (AIRepository, AIRequest, AIResponse, ...)
├── data/             Provayderdan mustaqil implementatsiya (providers/, session/, repositories/)
├── safety/           AISafetyService — placeholder interfeys, implementatsiyasiz
├── presentation/      Backend kontekstidagi "kirish nuqtasi" (AIServiceHandler)
└── di/               Kompozitsiya nuqtasi (AIServiceLocator)
```

Batafsil arxitektura: [`docs/AI_ARCHITECTURE.md`](../docs/AI_ARCHITECTURE.md).

## Ko'lam (Module 4, Phase 1)

Faqat arxitektura va poydevor. **Yo'q:** haqiqiy provayder chaqiruvi (HTTP/SDK), prompt matni/mazmuni, xavfsizlik tekshiruvi implementatsiyasi. Har bir provayder adapteri va xavfsizlik interfeysi ataylab `UnimplementedError`/konkret klasssiz qoldirilgan.

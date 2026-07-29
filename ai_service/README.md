# ai_service/ — AI Service Foundation (Module 4, Phase 1–4C)

**Bu papka Flutter mobil ilovaning (`lib/`) bir qismi EMAS.**

## Nega alohida

`docs/ARCHITECTURE.md`, "AI Service" bo'limi: *"AI Service klient tomonidan to'g'ridan-to'g'ri chaqirilmaydi — faqat Supabase backend (service role) orqali ishga tushiriladi."* `docs/DATABASE.md`da `ai_analyses` jadvaliga yozish **faqat service role** orqali ruxsat etilgan — client to'g'ridan-to'g'ri yoza olmaydi. Bu qoida `DEVELOPMENT_RULES.md`, 15–16-bandlar (AI xolisligi) va `docs/adr/ADR-005-ai-vendor-fallback.md`ning tavsiyasi bilan ham mos.

Shu sababli bu kod:
- **hech qachon** `lib/` ichidagi hech bir fayl tomonidan import qilinmaydi;
- provayder API kalitlarini (OpenAI/Gemini/Claude) hech qachon o'zida saqlamaydi yoki mobil ilova binariga joylashtirmaydi;
- kelgusida **backend/serverless muhitda** (Supabase Edge Function yoki alohida Dart xizmati) joylashtirilishi mo'ljallangan.

**Avtomatik tekshiruv:** `test/ai_service/architecture_boundary_test.dart` `ai_service/`ning har bir faylini skanerlab, `package:flutter`/`dart:ui`/`lib/`/`package:adolat_ai` importlaridan birortasi topilsa testni muvaffaqiyatsiz qiladi — bu chegara endi faqat kod ko'rib chiqishga emas, `flutter test`ning o'ziga tayanadi.

## Nega shu repozitoriyada

`flutter analyze`/`flutter test` (loyihaning yagona sifat darvozasi — `.github/workflows/ci.yml`) shu papkani ham avtomatik tekshiradi, chunki u bir xil `pubspec.yaml` konteksti ostida yotadi. Bu — kod hali qayerda ishga tushishi (Edge Function/alohida xizmat) aniq belgilanmagan bosqichda ham, sifat nazoratini birinchi kundan boshlab ta'minlash uchun ataylab qilingan tanlov.

## Tuzilma

```
ai_service/
├── domain/          Sof Dart — interfeyslar, modellar, usecase'lar, retry/xatolik abstraksiyasi
│   ├── entities/     AIRequest, AIResponse, AIConversation, AIMessage, AIContext, AIStreamEvent, AIFailure, ...
│   ├── repositories/ AIRepository, ConversationRepository, AICancellationRegistry (abstrakt)
│   ├── retry/        AIRetryPolicy, AIRetryExecutor (streaming-xavfsiz qayta urinish)
│   ├── usecases/     StartConversation/SendConversationMessage/CancelConversation/CloseConversation
│   └── prompt/       PromptPipeline, 5 ta PromptContext, ContextAssembler
├── protocol/         Klient ↔ backend SIMLI (wire) shartnoma — AIRequestEnvelope, AIResponseEnvelope,
│                     AIProtocolStreamEvent, AIProtocolError, va Phase 4B kontraktlari (credential,
│                     rate-limit/kvota holati, fayl yuklash, versiya kelishuvi) — JSON serializatsiya,
│                     domain/dan mustaqil
├── gateway/          Protokolni ijro etiladigan zanjirga ulaydi — auth/, dispatch/, timeout/,
│                     connectivity/, transport/ (Phase 3B), endpoint/, validation/, ratelimit/
│                     (Phase 4B) va attachment/ (Phase 4C)
├── data/             Provayderdan mustaqil implementatsiya (providers/, session/, repositories/)
├── safety/           AISafetyService — placeholder interfeys, implementatsiyasiz
├── presentation/      Backend kontekstidagi "kirish nuqtasi" (AIServiceHandler, yupqa/thin)
└── di/               Kompozitsiya nuqtasi (AIServiceLocator) — Phase 4C'dan beri qisman pluggable
```

Batafsil arxitektura: [`docs/AI_ARCHITECTURE.md`](../docs/AI_ARCHITECTURE.md).

## Ko'lam (Module 4, Phase 1–4C)

Faqat arxitektura, poydevor va shartnoma (kontrakt) — hech qanday haqiqiy ijro emas. **Yo'q:** haqiqiy provayder chaqiruvi (HTTP/SDK), prompt matni/mazmuni, xavfsizlik tekshiruvi implementatsiyasi, backend/Edge Function implementatsiyasi, `protocol/`ni haqiqiy HTTP/WebSocket handlerga ulash. Har bir provayder adapteri va xavfsizlik interfeysi ataylab `UnimplementedError`/konkret klasssiz qoldirilgan. Phase 4B qo'shgan validatsiya/rate-limit/kvota/persistensiya kontraktlari Phase 4C'da `AIGatewayImpl`/`AIServiceLocator`ga qisman ulandi (rate-limit/kvota — ixtiyoriy, standart holatda o'chirilgan; qolganlari hamon faqat shakl) — `docs/AI_ARCHITECTURE.md`, "Backend Implementation Readiness (Module 4, Phase 4C)".

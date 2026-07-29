# ai_service/ — AI Service Foundation (Module 4, Phase 1–4C; Module 5, Phase 5A–5B)

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
│   ├── accounting/   Token->xarajat hisob-kitobi + AITokenAccountingSink (Phase 4B/4C)
│   ├── quota/        Foydalanuvchi darajasidagi kunlik/oylik so'rov kvotasi (Phase 4B)
│   ├── case/         Case/CaseStatus/CaseCategory/CasePriority/CaseTimeline + intake/
│   │                 (CaseIntakeAssistant -- Module 5, Phase 5B)
│   └── prompt/       PromptPipeline, 5 ta PromptContext, ContextAssembler
├── protocol/         Klient ↔ backend SIMLI (wire) shartnoma — AIRequestEnvelope, AIResponseEnvelope,
│                     AIProtocolStreamEvent, AIProtocolError, va Phase 4B kontraktlari (credential,
│                     rate-limit/kvota holati, fayl yuklash, versiya kelishuvi) — JSON serializatsiya,
│                     domain/dan mustaqil
├── gateway/          Protokolni ijro etiladigan zanjirga ulaydi — auth/, dispatch/, timeout/,
│                     connectivity/, transport/ (Phase 3B), endpoint/, validation/, ratelimit/
│                     (Phase 4B) va attachment/ (Phase 4C)
├── config/           AI provayder/admin KONFIGURATSIYASI (Module 5, Phase 5A) — domain/
│                     (AIProviderConfig va h.k., provayderdan mustaqil), runtime/
│                     (AIRuntimeConfig, AICredentialResolver -- interfeys), admin/
│                     (4 ta boshqaruv interfeysi, UI yo'q)
├── data/             Provayderdan mustaqil implementatsiya (providers/, session/, repositories/,
│                     intake/ -- MockCaseIntakeAssistant, Phase 5B)
├── safety/           AISafetyService — placeholder interfeys, implementatsiyasiz
├── presentation/      Backend kontekstidagi "kirish nuqtasi" (AIServiceHandler, yupqa/thin)
└── di/               Kompozitsiya nuqtasi (AIServiceLocator) — Phase 4C'dan beri qisman pluggable,
                       Phase 5A'dan beri runtime config -> providerCredentials ko'prigi bilan
```

Batafsil arxitektura: [`docs/AI_ARCHITECTURE.md`](../docs/AI_ARCHITECTURE.md).

## Ko'lam (Module 4, Phase 1–4C; Module 5, Phase 5A–5B)

Faqat arxitektura, poydevor va shartnoma (kontrakt) — hech qanday haqiqiy ijro emas. **Yo'q:** haqiqiy provayder chaqiruvi (HTTP/SDK), prompt matni/mazmuni, xavfsizlik tekshiruvi implementatsiyasi, backend/Edge Function implementatsiyasi, `protocol/`ni haqiqiy HTTP/WebSocket handlerga ulash. Har bir provayder adapteri va xavfsizlik interfeysi ataylab `UnimplementedError`/konkret klasssiz qoldirilgan. Phase 4B qo'shgan validatsiya/rate-limit/kvota/persistensiya kontraktlari Phase 4C'da `AIGatewayImpl`/`AIServiceLocator`ga qisman ulandi (rate-limit/kvota — ixtiyoriy, standart holatda o'chirilgan; qolganlari hamon faqat shakl). Module 5, Phase 5A — AI provayderlarning O'ZINI (yoqilgan/o'chirilgan, model, limitlar, xarajat) admin/backend darajasida boshqarish kontrakti — API kalitlar hech qachon Flutter ilovasida bo'lmaydi, faqat `AICredentialReference` (ishora, kalit emas) orqali `AICredentialResolver`ga (interfeys, implementatsiyasiz) uzatiladi. Module 5, Phase 5B — foydalanuvchiga qaratilgan `Case` mavhumligi (toifa/muhimlik/hayot-davri/suhbat ishorasi) va uni `AIConversation`ga bog'lovchi intake oqimi — FAQAT soxta (mock) savol generatori bilan, hech qanday huquqiy xulosa/haqiqiy AI. Qarang: `docs/AI_ARCHITECTURE.md`, "Backend Implementation Readiness (Module 4, Phase 4C)", "AI Configuration and Control Foundation (Module 5, Phase 5A)" va "AI Case and Conversation Foundation (Module 5, Phase 5B)".

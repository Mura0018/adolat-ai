import '../domain/entities/ai_request.dart';
import '../domain/entities/ai_response.dart';
import 'ai_safety_check_result.dart';

/// Xavfsizlik qatlamining shartnomasi (Module 4 talabi: "Create
/// placeholder interfaces... No implementation yet").
///
/// **Kelgusi mas'uliyatlar (hozircha implementatsiya qilinmagan):**
/// - **Prompt validation** — foydalanuvchi kiritgan matn AI'ga
///   yuborishdan oldin tekshiriladi (masalan prompt-injection
///   urinishlari, haddan tashqari uzun matn).
/// - **Sensitive data filtering** — `docs/adr/ADR-006-hybrid-
///   infrastructure-strategy.md`da belgilangan sezgir toifalar
///   (pasport, PINFL/JShShIR va h.k.) tasodifan prompt matniga
///   tushib qolmasligini tekshirish.
/// - **Legal safety checks** — `DEVELOPMENT_RULES.md`, 15–16-bandlar
///   (AI xolisligi) amalda buzilmaganini tasdiqlash — masalan
///   `SafetyContext.requiresImpartiality == true` bo'lgan nizo
///   tahlilida ikkala tomon fakti borligini tekshirish.
///
/// Bu interfeys uchun hozircha **hech qanday konkret klass yozilmagan**
/// — `ai_service/di/ai_service_locator.dart` buni ataylab ochiq
/// qoldiradi (bog'lanmagan implementatsiya kelgusi bosqichda
/// qo'shiladi).
abstract interface class AISafetyService {
  Future<AISafetyCheckResult> validateRequest(AIRequest request);

  Future<AISafetyCheckResult> validateResponse(AIResponse response);
}

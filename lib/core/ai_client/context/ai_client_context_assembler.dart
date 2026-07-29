import 'ai_client_case_context.dart';
import 'ai_client_memory_context.dart';
import 'ai_client_safety_context.dart';
import 'ai_client_system_context.dart';
import 'ai_client_user_context.dart';

/// Beshta kanonik context'ni (System/User/Case/Memory/Safety) bitta
/// `Map<String, dynamic>`ga (`AiRequestEnvelope.context`) yig'uvchi,
/// tur-xavfsiz qurilmoqchi -- backend `ContextAssembler`
/// (`ai_service/domain/prompt/context_assembler.dart`) bilan bir xil
/// qat'iy shartnoma, klient tomonida.
///
/// **Majburiy:** `systemContext`, `userContext`, `safetyContext` --
/// backend tomonidagi bir xil talab bilan mos (`DEVELOPMENT_RULES.md`,
/// 15-16-bandlar -- xolislik talabini "unutib qoldirish" mumkin
/// bo'lmasligi kerak).
///
/// **Ixtiyoriy:** `caseContext`, `memoryContext`.
class AiClientContextAssembler {
  const AiClientContextAssembler({
    required this.systemContext,
    required this.userContext,
    required this.safetyContext,
    this.caseContext,
    this.memoryContext,
  });

  final AiClientSystemContext systemContext;
  final AiClientUserContext userContext;
  final AiClientSafetyContext safetyContext;
  final AiClientCaseContext? caseContext;
  final AiClientMemoryContext? memoryContext;

  /// `AiRequestEnvelope.context`ga to'g'ridan-to'g'ri joylanadigan
  /// xaritani quradi. Ixtiyoriy context'lar `null` bo'lsa, ularning
  /// kaliti xaritada umuman mavjud bo'lmaydi.
  Map<String, dynamic> assemble() {
    return {
      systemContext.contextKey: systemContext.toPromptData(),
      userContext.contextKey: userContext.toPromptData(),
      safetyContext.contextKey: safetyContext.toPromptData(),
      if (caseContext case final context?) context.contextKey: context.toPromptData(),
      if (memoryContext case final context?) context.contextKey: context.toPromptData(),
    };
  }
}

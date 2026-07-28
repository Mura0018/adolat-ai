import '../entities/ai_context.dart';
import 'case_context.dart';
import 'memory_context.dart';
import 'prompt_pipeline.dart';
import 'safety_context.dart';
import 'system_context.dart';
import 'user_context.dart';

/// Beshta kanonik context'ni (System/User/Case/Memory/Safety) bitta
/// `AIContext`ga yig'uvchi, tur-xavfsiz (type-safe) qurilmoqchi (Module
/// 4, Phase 2B talabi: "Create Context Assembler").
///
/// `PromptPipeline` (`prompt_pipeline.dart`) — umumiy maqsadli, istalgan
/// sonli/turdagi `PromptContext` bilan ishlaydi. `ContextAssembler` esa
/// shu umumiy mexanizm ustiga qurilgan, **shu loyihaga xos** qat'iy
/// shartnoma: qaysi context'lar **majburiy**, qaysilari **ixtiyoriy**
/// ekanligini konstruktor darajasida (kompilyatsiya vaqtida) ifodalaydi
/// — `PromptPipeline`ning o'zi buni bilmaydi (u har qanday kombinatsiyani
/// qabul qiladi, hatto bo'sh bo'lsa ham).
///
/// **Majburiy:** `systemContext`, `userContext`, `safetyContext` — har
/// bir AI so'rovida til/rejim, kim so'raganini va xavfsizlik bayroqlarini
/// ANIQ belgilash talab qilinadi (`DEVELOPMENT_RULES.md`, 15–16-bandlar
/// — xolislik talabini "unutib qoldirish" mumkin bo'lmasligi kerak).
///
/// **Ixtiyoriy:** `caseContext` (murojaat/nizoga bog'lanmagan umumiy
/// huquqiy savol bo'lishi mumkin), `memoryContext` (bitta martalik
/// so'rovda tarix yo'q).
class ContextAssembler {
  const ContextAssembler({
    required this.systemContext,
    required this.userContext,
    required this.safetyContext,
    this.caseContext,
    this.memoryContext,
  });

  final SystemContext systemContext;
  final UserContext userContext;
  final SafetyContext safetyContext;
  final CaseContext? caseContext;
  final MemoryContext? memoryContext;

  /// Barcha berilgan context'larni bitta `AIContext`ga yig'adi.
  /// Ixtiyoriy context'lar `null` bo'lsa, ularning kaliti
  /// `AIContext.sections`da umuman mavjud bo'lmaydi (bo'sh/placeholder
  /// qiymat bilan emas) — chaqiruvchi tomon `sectionFor('case') == null`
  /// orqali "bu so'rov muayyan ishga bog'lanmagan" holatini aniq
  /// ajrata oladi.
  AIContext assemble() {
    var pipeline = const PromptPipeline()
        .withContext(systemContext)
        .withContext(userContext)
        .withContext(safetyContext);

    if (caseContext case final context?) {
      pipeline = pipeline.withContext(context);
    }
    if (memoryContext case final context?) {
      pipeline = pipeline.withContext(context);
    }

    return pipeline.compose();
  }
}

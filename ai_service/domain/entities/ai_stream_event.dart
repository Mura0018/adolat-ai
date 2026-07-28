import 'ai_response.dart';

/// `AIRepository.sendMessage()` chiqaradigan oqim hodisasi — Module 4
/// talabi: "Streaming-ready design". Provayder token-token (delta)
/// javob bersa ham, bitta yakuniy javob bersa ham, ikkalasi ham shu bir
/// xil shartnoma orqali ifodalanadi.
///
/// Dart 3'ning **native** `sealed class`i ishlatilgan (Freezed emas —
/// `ai_message.dart`dagi izohga qarang) — chaqiruvchi tomon baribir
/// to'liq (exhaustive) `switch` pattern-matching qila oladi, xuddi
/// loyihaning boshqa joylarida (`core/network/result.dart`) qilingani
/// kabi.
sealed class AIStreamEvent {
  const AIStreamEvent();
}

/// Qisman (delta) matn bo'lagi — provayder token-token oqim bersa.
final class AIStreamEventChunk extends AIStreamEvent {
  const AIStreamEventChunk({required this.deltaContent});

  final String deltaContent;
}

/// Oqim muvaffaqiyatli yakunlandi — to'liq `AIResponse` bilan.
final class AIStreamEventDone extends AIStreamEvent {
  const AIStreamEventDone({required this.response});

  final AIResponse response;
}

/// Bekor qilindi (`AICancellationToken.cancel()` orqali) — xatolik
/// emas, foydalanuvchi/tizim tomonidan ataylab to'xtatilgan holat.
final class AIStreamEventCancelled extends AIStreamEvent {
  const AIStreamEventCancelled();
}

/// Provayder yoki xavfsizlik qatlami xatolik qaytardi. `message` —
/// xom xatolik emas, allaqachon xavfsiz (foydalanuvchiga ko'rsatilishi
/// mumkin bo'lgan) matn bo'lishi kerak — flutter klientdagi
/// `Failure`/`describeErrorForUser()` konventsiyasiga muvofiq
/// (docs/ARCHITECTURE.md, "Error Handling").
final class AIStreamEventError extends AIStreamEvent {
  const AIStreamEventError({required this.message});

  final String message;
}

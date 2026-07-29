/// `CaseRepository`/`Case` tashlaydigan, ANIQ AJRATILADIGAN
/// (distinguishable) xatolik turlari -- `domain/repositories/
/// conversation_exceptions.dart` (Module 4, Phase 2C) bilan bir xil
/// konventsiya: hammasi kutilgan, oldindan bilingan ish vaqti
/// holatlari (dasturlash xatosi EMAS), shuning uchun `Error` o'rniga
/// `Exception` interfeysini amalga oshiradi.
library;

/// Berilgan `caseId` bo'yicha ish topilmadi.
class CaseNotFoundException implements Exception {
  const CaseNotFoundException(this.caseId);

  final String caseId;

  @override
  String toString() => 'CaseNotFoundException($caseId)';
}

/// `CaseStatus`ning bir holatidan ikkinchisiga o'tish mantiqan
/// noto'g'ri (`case_status.dart`dagi [isValidCaseStatusTransition]ga
/// qarang -- masalan `archived`dan chiqishga urinish).
class InvalidCaseStatusTransitionException implements Exception {
  const InvalidCaseStatusTransitionException({required this.from, required this.to});

  final Object from;
  final Object to;

  @override
  String toString() => 'InvalidCaseStatusTransitionException(from: $from, to: $to)';
}

/// Foydalanuvchi o'ziga tegishli BO'LMAGAN ishga kirishga urindi
/// (Module 5, Phase 5B talabi: "Security Rules -- User can only access
/// own cases"). Dasturlash xatosi emas -- soxtalashtirish (spoofing)
/// urinishi yoki eskirgan klient holati, `AIUnauthorizedFailure`
/// (`domain/entities/ai_failure.dart`, Module 4, Phase 3B) bilan bir
/// xil ruh.
class CaseAccessDeniedException implements Exception {
  const CaseAccessDeniedException({required this.caseId, required this.requestingUserId});

  final String caseId;
  final String requestingUserId;

  @override
  String toString() =>
      'CaseAccessDeniedException(caseId: $caseId, requestingUserId: $requestingUserId)';
}

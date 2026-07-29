import '../../../features/attachments/domain/entities/case_type.dart';
import 'ai_client_prompt_context.dart';

/// Qaysi ish (murojaat/nizo) haqida tahlil so'ralayotgani -- backend
/// `CaseContext` bilan wire-shaklda mos, `docs/DATABASE.md`dagi
/// "mutually exclusive FK" naqshiga muvofiq.
///
/// `CaseType`ni `features/attachments/`dan qayta ishlatadi (`lib/`
/// ICHIDAGI qayta foydalanish -- `ai_client_user_context.dart`dagi
/// izohga qarang).
class AiClientCaseContext implements AiClientPromptContext {
  const AiClientCaseContext({
    required this.caseType,
    this.appealId,
    this.disputeId,
    this.categoryName,
    this.hasBothPartyStatements,
  }) : assert(
         (caseType == CaseType.appeal && appealId != null && disputeId == null) ||
             (caseType == CaseType.dispute && disputeId != null && appealId == null),
         'caseType == appeal bo\'lsa faqat appealId, dispute bo\'lsa faqat '
         'disputeId berilishi shart',
       );

  final CaseType caseType;
  final String? appealId;
  final String? disputeId;
  final String? categoryName;

  /// Faqat `caseType == CaseType.dispute` uchun ma'noli.
  final bool? hasBothPartyStatements;

  @override
  String get contextKey => 'case';

  @override
  Map<String, dynamic> toPromptData() => {
    'case_type': caseType.dbValue,
    if (appealId != null) 'appeal_id': appealId,
    if (disputeId != null) 'dispute_id': disputeId,
    if (categoryName != null) 'category_name': categoryName,
    if (hasBothPartyStatements != null) 'has_both_party_statements': hasBothPartyStatements,
  };
}

import 'prompt_context.dart';

/// Qaysi ish (murojaat/nizo) haqida tahlil so'ralayotgani
/// (`docs/DATABASE.md`, "Umumiy konventsiyalar" — "mutually exclusive
/// FK" naqshiga muvofiq, faqat `appealId` **yoki** `disputeId`dan
/// bittasi berilishi kutiladi).
///
/// Nizo (dispute) uchun `DEVELOPMENT_RULES.md`, 15–16-bandlar
/// ("AI hech qachon bir tomon foydasiga qaror chiqarmaydi") shu
/// context orqali ta'minlanadi: `hasBothPartyStatements` maydoni
/// tahlil bir tomonlama ma'lumot asosida ekanligini keyingi
/// bosqichda (haqiqiy prompt yozilganda) ochiq belgilash uchun.
class CaseContext implements PromptContext {
  const CaseContext({
    required this.caseType,
    this.appealId,
    this.disputeId,
    this.categoryName,
    this.hasBothPartyStatements,
  }) : assert(
         (appealId != null) ^ (disputeId != null),
         'appealId yoki disputeId\'dan aynan bittasi berilishi shart',
       );

  final String caseType;
  final String? appealId;
  final String? disputeId;
  final String? categoryName;

  /// Faqat `caseType == 'dispute'` uchun ma'noli.
  final bool? hasBothPartyStatements;

  @override
  String get contextKey => 'case';

  @override
  Map<String, dynamic> toPromptData() {
    return {
      'case_type': caseType,
      if (appealId != null) 'appeal_id': appealId,
      if (disputeId != null) 'dispute_id': disputeId,
      if (categoryName != null) 'category_name': categoryName,
      if (hasBothPartyStatements != null)
        'has_both_party_statements': hasBothPartyStatements,
    };
  }
}

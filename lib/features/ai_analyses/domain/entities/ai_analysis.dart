import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../attachments/domain/entities/case_type.dart';

part 'ai_analysis.freezed.dart';

/// `public.ai_analyses` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 8-jadval). Faqat o'qish uchun — bu jadvalga yozish
/// faqat service role orqali amalga oshadi (docs/SECURITY.md, "Supabase
/// RLS Security" bo'limi).
@freezed
class AiAnalysis with _$AiAnalysis {
  const factory AiAnalysis({
    required String id,
    required CaseType caseType,
    String? appealId,
    String? disputeId,
    required String analysisText,
    String? legalBasisSummary,
    double? confidenceScore,
    required String modelVersion,
    required DateTime createdAt,
  }) = _AiAnalysis;
}

// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../attachments/domain/entities/case_type.dart';
import '../../domain/entities/ai_analysis.dart';

part 'ai_analysis_model.freezed.dart';
part 'ai_analysis_model.g.dart';

/// `public.ai_analyses` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 8-jadval).
@freezed
class AiAnalysisModel with _$AiAnalysisModel {
  const factory AiAnalysisModel({
    required String id,
    @JsonKey(name: 'case_type') required String caseType,
    @JsonKey(name: 'appeal_id') String? appealId,
    @JsonKey(name: 'dispute_id') String? disputeId,
    @JsonKey(name: 'analysis_text') required String analysisText,
    @JsonKey(name: 'legal_basis_summary') String? legalBasisSummary,
    @JsonKey(name: 'confidence_score') num? confidenceScore,
    @JsonKey(name: 'model_version') required String modelVersion,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _AiAnalysisModel;

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$AiAnalysisModelFromJson(json);
}

extension AiAnalysisModelX on AiAnalysisModel {
  AiAnalysis toEntity() {
    return AiAnalysis(
      id: id,
      caseType: CaseType.fromDbValue(caseType),
      appealId: appealId,
      disputeId: disputeId,
      analysisText: analysisText,
      legalBasisSummary: legalBasisSummary,
      confidenceScore: confidenceScore?.toDouble(),
      modelVersion: modelVersion,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

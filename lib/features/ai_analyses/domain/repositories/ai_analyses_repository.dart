import '../../../../core/network/result.dart';
import '../entities/ai_analysis.dart';

/// AI tahlili natijalarini o'qish uchun abstrakt shartnoma
/// (docs/DATABASE.md, 8-jadval). Yozish siyosati yo'q — bu repository
/// atayin faqat o'qish (read-only) amallarini taqdim etadi.
abstract interface class AiAnalysesRepository {
  Future<Result<List<AiAnalysis>>> listForAppeal(String appealId);

  Future<Result<List<AiAnalysis>>> listForDispute(String disputeId);
}

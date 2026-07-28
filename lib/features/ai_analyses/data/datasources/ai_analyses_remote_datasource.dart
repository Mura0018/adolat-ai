import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_client.dart';
import '../models/ai_analysis_model.dart';

/// `public.ai_analyses`ni faqat o'qish uchun datasource
/// (docs/DATABASE.md, 8-jadval). INSERT/UPDATE/DELETE bu klassda yo'q —
/// RLS ham buni faqat service role'ga ruxsat beradi.
class AiAnalysesRemoteDataSource {
  AiAnalysesRemoteDataSource();

  SupabaseClient get _client => SupabaseService.client;

  Future<List<AiAnalysisModel>> listForAppeal(String appealId) async {
    final rows = await _client
        .from('ai_analyses')
        .select()
        .eq('appeal_id', appealId)
        .order('created_at');

    return (rows as List)
        .map((row) => AiAnalysisModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AiAnalysisModel>> listForDispute(String disputeId) async {
    final rows = await _client
        .from('ai_analyses')
        .select()
        .eq('dispute_id', disputeId)
        .order('created_at');

    return (rows as List)
        .map((row) => AiAnalysisModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

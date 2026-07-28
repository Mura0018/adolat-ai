import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_client.dart';
import '../models/dispute_model.dart';

/// `public.disputes` bilan to'g'ridan-to'g'ri ishlaydigan Supabase
/// datasource'i (docs/DATABASE.md, 6-jadval).
///
/// Bu klass hech qanday ruxsat tekshiruvini o'zi amalga oshirmaydi —
/// yakuniy avtorizatsiya har doim server tomonidagi RLS orqali
/// ta'minlanadi (supabase/migrations/20260726000002_rls_policies.sql).
class DisputesRemoteDataSource {
  DisputesRemoteDataSource();

  SupabaseClient get _client => SupabaseService.client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
        'Bu amal uchun foydalanuvchi tizimga kirgan bo\'lishi kerak',
      );
    }
    return id;
  }

  Future<DisputeModel> createWithUnregisteredRespondent({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  }) async {
    final row = await _client
        .from('disputes')
        .insert({
          'initiator_id': _requireUserId,
          'category_id': categoryId,
          'title': title,
          'description': description,
          'respondent_type': 'unregistered',
          'respondent_display_name': respondentDisplayName,
        })
        .select()
        .single();

    return DisputeModel.fromJson(row);
  }

  Future<DisputeModel> updateAsInitiator({
    required String disputeId,
    String? title,
    String? description,
  }) async {
    final patch = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };

    final row = await _client
        .from('disputes')
        .update(patch)
        .eq('id', disputeId)
        .select()
        .single();

    return DisputeModel.fromJson(row);
  }

  Future<DisputeModel> submitRespondentStatement({
    required String disputeId,
    required String statement,
  }) async {
    final row = await _client
        .from('disputes')
        .update({'respondent_statement': statement})
        .eq('id', disputeId)
        .select()
        .single();

    return DisputeModel.fromJson(row);
  }

  Future<void> deleteAsInitiator(String disputeId) async {
    await _client.from('disputes').delete().eq('id', disputeId);
  }

  Future<DisputeModel> getById(String disputeId) async {
    final row = await _client
        .from('disputes')
        .select()
        .eq('id', disputeId)
        .single();

    return DisputeModel.fromJson(row);
  }

  Future<List<DisputeModel>> listMine() async {
    final userId = _requireUserId;
    final rows = await _client
        .from('disputes')
        .select()
        .or('initiator_id.eq.$userId,respondent_profile_id.eq.$userId')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => DisputeModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

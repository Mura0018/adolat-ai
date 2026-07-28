import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_client.dart';
import '../models/appeal_model.dart';

/// `public.appeals` bilan to'g'ridan-to'g'ri ishlaydigan Supabase
/// datasource'i (docs/DATABASE.md, 5-jadval).
///
/// Bu klass hech qanday ruxsat tekshiruvini o'zi amalga oshirmaydi —
/// yakuniy avtorizatsiya har doim server tomonidagi RLS orqali
/// ta'minlanadi (supabase/migrations/20260726000002_rls_policies.sql).
class AppealsRemoteDataSource {
  AppealsRemoteDataSource();

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

  Future<AppealModel> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    final row = await _client
        .from('appeals')
        .insert({
          'author_id': _requireUserId,
          'category_id': categoryId,
          'recipient_body_id': recipientBodyId,
          'title': title,
          'body_text': bodyText,
          'ai_draft_text': aiDraftText,
        })
        .select()
        .single();

    return AppealModel.fromJson(row);
  }

  Future<AppealModel> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    final patch = <String, dynamic>{
      if (title != null) 'title': title,
      if (bodyText != null) 'body_text': bodyText,
    };

    final row = await _client
        .from('appeals')
        .update(patch)
        .eq('id', appealId)
        .select()
        .single();

    return AppealModel.fromJson(row);
  }

  /// `status`ni `submitted`ga o'tkazadi va `submitted_at`ni belgilaydi.
  Future<AppealModel> submit(String appealId) async {
    final row = await _client
        .from('appeals')
        .update({
          'status': 'submitted',
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', appealId)
        .select()
        .single();

    return AppealModel.fromJson(row);
  }

  Future<void> deleteDraft(String appealId) async {
    await _client.from('appeals').delete().eq('id', appealId);
  }

  Future<AppealModel> getById(String appealId) async {
    final row = await _client
        .from('appeals')
        .select()
        .eq('id', appealId)
        .single();

    return AppealModel.fromJson(row);
  }

  Future<List<AppealModel>> listMine() async {
    final rows = await _client
        .from('appeals')
        .select()
        .eq('author_id', _requireUserId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => AppealModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

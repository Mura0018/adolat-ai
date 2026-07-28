import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_client.dart';
import '../models/government_body_model.dart';
import '../models/legal_category_model.dart';

/// `public.legal_categories` va `public.government_bodies` bilan
/// to'g'ridan-to'g'ri ishlaydigan Supabase datasource'i.
///
/// RLS: ikkalasi ham autentifikatsiyalangan foydalanuvchiga public read
/// (docs/DATABASE.md, 3 va 4-jadval "RLS talablari"; docs/SECURITY.md,
/// "Supabase RLS Security" bo'limi) — bu klass qo'shimcha ruxsat
/// tekshiruvini o'zi amalga oshirmaydi, faqat server RLS'iga tayanadi.
class LegalReferenceRemoteDataSource {
  LegalReferenceRemoteDataSource();

  SupabaseClient get _client => SupabaseService.client;

  Future<List<LegalCategoryModel>> getActiveLegalCategories() async {
    final rows = await _client
        .from('legal_categories')
        .select()
        .eq('is_active', true)
        .order('name_uz');

    return (rows as List)
        .map((row) => LegalCategoryModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<GovernmentBodyModel>> getActiveGovernmentBodies() async {
    final rows = await _client
        .from('government_bodies')
        .select()
        .eq('is_active', true)
        .order('name');

    return (rows as List)
        .map(
          (row) => GovernmentBodyModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }
}

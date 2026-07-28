import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/storage_service.dart';
import '../../../../services/supabase/supabase_client.dart';
import '../../domain/entities/case_type.dart';
import '../models/case_attachment_model.dart';

/// `public.attachments` va `case-attachments` Storage bucket'i bilan
/// birgalikda ishlaydigan datasource (docs/DATABASE.md, 11-jadval;
/// supabase/migrations/20260726000003_storage_foundation.sql).
class AttachmentsRemoteDataSource {
  AttachmentsRemoteDataSource();

  SupabaseClient get _client => SupabaseService.client;

  Future<CaseAttachmentModel> upload({
    required CaseType caseType,
    required String caseId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw StateError('Fayl yuklash uchun foydalanuvchi tizimga kirgan bo\'lishi kerak');
    }

    // 1) Avval haqiqiy fayl Storage'ga yuklanadi — Storage RLS ham xuddi
    //    shu case egaligini alohida tekshiradi (ikki qatlamli himoya).
    final storagePath = await CaseAttachmentStorage.uploadCaseAttachment(
      caseType: caseType.dbValue,
      caseId: caseId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );

    // 2) Fayl muvaffaqiyatli yuklangach, metadata public.attachments'ga
    //    yoziladi. Agar shu yerda xatolik yuz bersa, Storage'dagi fayl
    //    "yetim" (orphaned) qolishi mumkin — bu holat quyi darajadagi
    //    (application) tozalash jarayoni talab qiladi va hozircha ushbu
    //    foundation doirasidan tashqarida.
    final row = await _client
        .from('attachments')
        .insert({
          'case_type': caseType.dbValue,
          'appeal_id': caseType == CaseType.appeal ? caseId : null,
          'dispute_id': caseType == CaseType.dispute ? caseId : null,
          'uploaded_by': currentUserId,
          'storage_path': storagePath,
          'file_name': fileName,
          'mime_type': contentType,
          'size_bytes': bytes.length,
        })
        .select()
        .single();

    return CaseAttachmentModel.fromJson(row);
  }

  Future<List<CaseAttachmentModel>> listForAppeal(String appealId) async {
    final rows = await _client
        .from('attachments')
        .select()
        .eq('appeal_id', appealId)
        .order('created_at');

    return (rows as List)
        .map((row) => CaseAttachmentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseAttachmentModel>> listForDispute(String disputeId) async {
    final rows = await _client
        .from('attachments')
        .select()
        .eq('dispute_id', disputeId)
        .order('created_at');

    return (rows as List)
        .map((row) => CaseAttachmentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> getSignedDownloadUrl(String storagePath) {
    return CaseAttachmentStorage.createSignedUrl(storagePath);
  }

  Future<void> delete({
    required String id,
    required String storagePath,
  }) async {
    await _client.from('attachments').delete().eq('id', id);
    await CaseAttachmentStorage.remove(storagePath);
  }
}

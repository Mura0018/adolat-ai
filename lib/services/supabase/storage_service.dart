import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// `case-attachments` Supabase Storage bucket'i ustidan yupqa (thin) wrapper.
///
/// Bucket, ruxsat etilgan fayl turlari, maksimal hajm va fayl yo'li
/// konventsiyasi `supabase/migrations/20260726000003_storage_foundation.sql`da
/// belgilangan — bu klass o'sha migratsiyani TAKRORLAMAYDI, faqat unga mos
/// ravishda fayl yo'lini quradi va Storage API'ni chaqiradi. Haqiqiy
/// ruxsat tekshiruvi har doim server tomonida (Storage RLS) amalga
/// oshiriladi — bu klientdagi qiymatlar faqat foydalanuvchi tajribasini
/// yaxshilash uchun (masalan hajmdan oshib ketganini oldindan bildirish).
abstract final class CaseAttachmentStorage {
  static const String bucketId = 'case-attachments';

  /// Bucket darajasida sozlangan maksimal fayl hajmi (baytlarda) — faqat
  /// mos foydalanuvchi xabari ko'rsatish uchun, haqiqiy cheklov Storage
  /// tomonida.
  static const int maxFileSizeBytes = 10485760; // 10 MB

  /// Bucket darajasida ruxsat etilgan fayl turlari — faqat mos
  /// foydalanuvchi xabari ko'rsatish uchun, haqiqiy cheklov Storage
  /// tomonida.
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  /// `supabase/migrations/20260726000003_storage_foundation.sql`da
  /// belgilangan `{case_type}/{case_id}/{fayl_nomi}` konventsiyasiga mos
  /// yo'lni quradi. `caseType` qat'iy ravishda `'appeal'` yoki `'dispute'`
  /// bo'lishi shart — Storage RLS siyosati aynan shu ikkita qiymatni
  /// tekshiradi.
  static String buildObjectPath({
    required String caseType,
    required String caseId,
    required String fileName,
  }) {
    assert(
      caseType == 'appeal' || caseType == 'dispute',
      'caseType faqat "appeal" yoki "dispute" bo\'lishi mumkin',
    );
    return '$caseType/$caseId/$fileName';
  }

  /// Faylni bucket'ga yuklaydi va `storage_path`ni qaytaradi.
  ///
  /// `public.attachments` jadvaliga mos yozuv yaratish bu klassning
  /// mas'uliyati emas — chaqiruvchi (`AttachmentsRemoteDataSource`)
  /// muvaffaqiyatli yuklashdan so'ng shu `storage_path` bilan tegishli
  /// jadvalga yozuv qo'shadi.
  static Future<String> uploadCaseAttachment({
    required String caseType,
    required String caseId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = buildObjectPath(
      caseType: caseType,
      caseId: caseId,
      fileName: fileName,
    );

    await SupabaseService.client.storage
        .from(bucketId)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return path;
  }

  /// Berilgan `storage_path` uchun vaqtinchalik (signed) yuklab olish
  /// havolasini hosil qiladi — bucket private bo'lgani sababli to'g'ridan-
  /// to'g'ri ochiq URL ishlamaydi.
  static Future<String> createSignedUrl(
    String storagePath, {
    Duration expiresIn = const Duration(minutes: 10),
  }) {
    return SupabaseService.client.storage
        .from(bucketId)
        .createSignedUrl(storagePath, expiresIn.inSeconds);
  }

  /// Faylni bucket'dan o'chiradi (masalan tegishli `attachments` yozuvi
  /// o'chirilganda, ikkalasi ham izchil qolishi uchun).
  static Future<void> remove(String storagePath) {
    return SupabaseService.client.storage.from(bucketId).remove([
      storagePath,
    ]);
  }
}

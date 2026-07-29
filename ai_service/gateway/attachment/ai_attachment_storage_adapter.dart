import '../../protocol/ai_attachment_metadata.dart';
import '../../protocol/ai_attachment_upload_contract.dart';

/// Fayl saqlash BACKEND ADAPTER CHEGARASI (Module 4, Phase 4C talabi:
/// "Prepare backend adapter boundaries" -- fayl yuklash uchun) --
/// **faqat interfeys, hech qanday implementatsiya yo'q**
/// (`AISafetyService`/`AIAuthenticator`/`AIProviderAdapter` bilan bir
/// xil, allaqachon o'rnatilgan konventsiya).
///
/// **`protocol/ai_attachment_upload_contract.dart` (Phase 4B) bilan
/// munosabati:** o'sha fayl `AIAttachmentUploadRequest`/
/// `AIAttachmentUploadTicket` SIMLI shaklini belgiladi, lekin ularni
/// KIM/QANDAY generatsiya qilishini (haqiqiy saqlash xizmati --
/// Supabase Storage, S3, ...) ochiq qoldirdi. `AIAttachmentStorageAdapter`
/// aynan shu bo'shliq -- `AIProviderAdapter` (`data/providers/`, Phase
/// 1) fayl yuklash uchun qanday ekvivalenti.
///
/// **Bu bosqichda YO'Q:** hech qanday konkret implementatsiya (masalan
/// `SupabaseStorageAdapter`). Bu ATAYLAB -- talab: "Do NOT implement
/// real AI calls" bilan bir xil ruhda, real Storage integratsiyasi ham
/// haqiqiy backend qurilish bosqichi, poydevor emas.
abstract interface class AIAttachmentStorageAdapter {
  /// [request]ga mos, hali yuklanmagan fayl uchun ruxsat (ticket)
  /// generatsiya qiladi -- `AIBackendEndpointId.requestAttachmentUpload`
  /// (`gateway/endpoint/`) shu metodni chaqirishi mo'ljallangan.
  Future<AIAttachmentUploadTicket> issueUploadTicket(
    AIAttachmentUploadRequest request, {
    required String userId,
  });

  /// Fayl haqiqatda yuklangandan KEYIN, yakuniy metadatani qaytaradi --
  /// masalan haqiqiy saqlash yo'lini (`storageRef`) tasdiqlash yoki
  /// hajmni serverda qayta tekshirish uchun.
  Future<AIAttachmentMetadata> finalizeUpload({
    required String attachmentId,
    required String storageRef,
  });
}

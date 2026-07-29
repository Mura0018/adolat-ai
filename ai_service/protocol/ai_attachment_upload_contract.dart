import 'ai_attachment_metadata.dart';

/// Fayl yuklashdan OLDINGI kelishuv bosqichining SIMLI (wire) shakli
/// (Module 4, Phase 4B talabi: "Attachment upload contract") --
/// `gateway/endpoint/ai_backend_endpoint.dart`dagi
/// `AIBackendEndpointId.requestAttachmentUpload` amali shu turlar bilan
/// ishlaydi.
///
/// **`AIAttachmentMetadata` (Phase 3A) bilan munosabati:** o'sha klass
/// -- allaqachon YUKLANGAN faylning metadatasi, `AIRequestEnvelope.attachments`
/// ichida yuriladi ("fayl mazmuni bu protokol orqali uzatilmaydi... u
/// alohida kanal orqali oldindan yuklanadi"). Bu fayl aynan o'sha
/// "alohida kanal"ning KELISHUV bosqichini rasmiylashtiradi: klient
/// avval [AIAttachmentUploadRequest] bilan ruxsat so'raydi, backend
/// [AIAttachmentUploadTicket] bilan javob beradi (qayerga yuklash
/// mumkinligi -- `uploadRef`, hali transport-agnostik, HAQIQIY
/// pre-signed URL emas), fayl haqiqatda yuklangandan KEYIN esa klient
/// `ticket.attachmentId`/`storageRef`ni `AIAttachmentMetadata.id`/
/// `storageRef` sifatida `AIRequestEnvelope.attachments`ga qo'shadi.
///
/// **Do NOT implement HTTP:** [AIAttachmentUploadTicket.uploadRef] --
/// haqiqiy pre-signed URL/Supabase Storage yo'li EMAS, faqat "qayerga
/// yuklash kerakligi"ni ifodalovchi mavhum (opaque) satr placeholder --
/// xuddi `AITokenUsage` (Phase 3A) barcha maydonlari `null` bo'lgani
/// kabi, haqiqiy qiymat kelgusi integratsiya bosqichida to'ldiriladi.
class AIAttachmentUploadRequest {
  const AIAttachmentUploadRequest({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
  };

  factory AIAttachmentUploadRequest.fromJson(Map<String, dynamic> json) {
    return AIAttachmentUploadRequest(
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIAttachmentUploadRequest &&
            other.fileName == fileName &&
            other.mimeType == mimeType &&
            other.sizeBytes == sizeBytes);
  }

  @override
  int get hashCode => Object.hash(fileName, mimeType, sizeBytes);

  @override
  String toString() =>
      'AIAttachmentUploadRequest(fileName: $fileName, sizeBytes: $sizeBytes)';
}

/// Backend so'rovni QABUL qilganda qaytaradigan ruxsat -- fayl mazmuni
/// hali yuklanmagan, faqat "qayerga yuklash mumkin" ma'lumoti.
class AIAttachmentUploadTicket {
  const AIAttachmentUploadTicket({
    required this.attachmentId,
    required this.uploadRef,
    required this.expiresAt,
  });

  /// Yakuniy `AIAttachmentMetadata.id` bilan bir xil bo'ladi -- backend
  /// oldindan generatsiya qiladi, shunda klient fayl yuklashni hali
  /// boshlamasdan turib ID'ni biladi (masalan UI'da darhol "yuklanmoqda"
  /// holatini ko'rsatish uchun).
  final String attachmentId;

  /// Qayerga yuklash kerakligi -- mavhum (opaque), transport-agnostik
  /// (yuqoridagi sinf izohiga qarang).
  final String uploadRef;

  /// Shu ticket qachongacha amal qiladi -- muddati o'tsa, klient qayta
  /// [AIAttachmentUploadRequest] yuborishi kerak.
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
    'attachmentId': attachmentId,
    'uploadRef': uploadRef,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory AIAttachmentUploadTicket.fromJson(Map<String, dynamic> json) {
    return AIAttachmentUploadTicket(
      attachmentId: json['attachmentId'] as String,
      uploadRef: json['uploadRef'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIAttachmentUploadTicket &&
            other.attachmentId == attachmentId &&
            other.uploadRef == uploadRef &&
            other.expiresAt == expiresAt);
  }

  @override
  int get hashCode => Object.hash(attachmentId, uploadRef, expiresAt);

  @override
  String toString() => 'AIAttachmentUploadTicket(attachmentId: $attachmentId)';
}

/// Fayl yuklashga qo'yiladigan cheklovlar -- `docs/SECURITY.md`, "Security
/// Checklist": "Fayl yuklash uchun MIME/hajm cheklovlari... ishlayotgani
/// tekshirilgan".
///
/// **Nega aniq son/ro'yxat bu yerda YO'Q:** loyihaning boshqa hech bir
/// joyida (masalan `lib/features/attachments/`) hali qattiq
/// kodlangan MIME/hajm chegarasi yo'q -- bu qaror hali qabul
/// qilinmagan (`gateway/ratelimit/ai_rate_limiter.dart`dagi
/// `AIRateLimitPolicy` bilan bir xil sabab: mahsulot jamoasi bilan
/// kelishilishi kerak bo'lgan biznes qarori, shu kontrakt bunga taxmin
/// qilmaydi). [AIAttachmentUploadConstraints] shuning uchun har doim
/// aniq qiymat bilan qurilishi shart, yashirin standart yo'q.
class AIAttachmentUploadConstraints {
  const AIAttachmentUploadConstraints({
    required this.maxSizeBytes,
    required this.allowedMimeTypes,
  }) : assert(maxSizeBytes > 0, 'maxSizeBytes musbat bo\'lishi kerak');

  final int maxSizeBytes;
  final Set<String> allowedMimeTypes;

  /// [request] shu cheklovlarga mos keladimi -- xolis (pure) tekshiruv,
  /// natija sifatida bitta yoki ikkita [AIRequestViolationCode]ga mos
  /// keluvchi sabab ro'yxati o'rniga, oddiy bool -- to'liq tur-xavfsiz
  /// tekshiruv `gateway/validation/ai_request_validation_contract.dart`ning
  /// ishi, bu yerdagisi faqat qiymat-darajasidagi (value-level) qulaylik.
  bool allows(AIAttachmentUploadRequest request) {
    return request.sizeBytes <= maxSizeBytes && allowedMimeTypes.contains(request.mimeType);
  }
}

/// `AIAttachmentMetadata`ning yakuniy shakli bilan bog'lash -- ticket
/// muvaffaqiyatli fayl yuklashdan keyin shu tarzda yakuniy metadataga
/// aylanadi (qulaylik funksiyasi, hech qanday tarmoq chaqiruvi yo'q).
AIAttachmentMetadata finalizeAttachmentUpload({
  required AIAttachmentUploadTicket ticket,
  required AIAttachmentUploadRequest request,
  required String storageRef,
}) {
  return AIAttachmentMetadata(
    id: ticket.attachmentId,
    fileName: request.fileName,
    mimeType: request.mimeType,
    sizeBytes: request.sizeBytes,
    storageRef: storageRef,
  );
}

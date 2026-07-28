/// So'rovga biriktirilgan faylning METADATASI — fayl bayt(lar)ining
/// o'zi emas (Module 4, Phase 3A talabi: "attachments metadata").
///
/// Fayl mazmuni bu protokol orqali uzatilmaydi — u alohida kanal
/// (masalan Supabase Storage) orqali oldindan yuklanadi, va
/// [storageRef] shu joyga ishora qiladi. Bu qasddan qilingan ajratish:
/// katta ikkilik (binary) ma'lumotni JSON konvertga (envelope)
/// qo'shish oqim (streaming) protokolini og'irlashtiradi va
/// `docs/SECURITY.md`dagi fayl yuklash oqimidan mustaqil bo'lishi
/// kerak.
class AIAttachmentMetadata {
  const AIAttachmentMetadata({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.storageRef,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  /// Faylning haqiqiy saqlanish joyiga ishora (masalan Supabase Storage
  /// yo'li). `null` bo'lishi mumkin -- masalan fayl hali yuklanish
  /// jarayonida bo'lsa.
  final String? storageRef;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    if (storageRef != null) 'storageRef': storageRef,
  };

  factory AIAttachmentMetadata.fromJson(Map<String, dynamic> json) {
    return AIAttachmentMetadata(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      storageRef: json['storageRef'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIAttachmentMetadata &&
            other.id == id &&
            other.fileName == fileName &&
            other.mimeType == mimeType &&
            other.sizeBytes == sizeBytes &&
            other.storageRef == storageRef);
  }

  @override
  int get hashCode => Object.hash(id, fileName, mimeType, sizeBytes, storageRef);

  @override
  String toString() =>
      'AIAttachmentMetadata(id: $id, fileName: $fileName, sizeBytes: $sizeBytes)';
}

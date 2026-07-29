/// So'rovga biriktirilgan faylning METADATASI -- fayl bayt(lar)ining o'zi
/// emas. `ai_service/protocol/ai_attachment_metadata.dart`ning klient
/// tomonidagi mustaqil ko'chirmasi (bir xil JSON shakli, mustaqil klass --
/// `ai_protocol_version.dart`dagi izohga qarang).
///
/// Fayl mazmuni bu protokol orqali uzatilmaydi -- alohida kanal (masalan
/// Supabase Storage) orqali oldindan yuklanadi, [storageRef] shu joyga
/// ishora qiladi.
class AiAttachmentMetadata {
  const AiAttachmentMetadata({
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
  final String? storageRef;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    if (storageRef != null) 'storageRef': storageRef,
  };

  factory AiAttachmentMetadata.fromJson(Map<String, dynamic> json) {
    return AiAttachmentMetadata(
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
        (other is AiAttachmentMetadata &&
            other.id == id &&
            other.fileName == fileName &&
            other.mimeType == mimeType &&
            other.sizeBytes == sizeBytes &&
            other.storageRef == storageRef);
  }

  @override
  int get hashCode => Object.hash(id, fileName, mimeType, sizeBytes, storageRef);

  @override
  String toString() => 'AiAttachmentMetadata(id: $id, fileName: $fileName)';
}

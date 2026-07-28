/// Suhbatdagi bitta xabarning rolini bildiradi.
enum AIMessageRole { system, user, assistant }

/// `AIConversation.messages` ichidagi bitta xabar. Foundation bosqichida
/// bu faqat ma'lumot tuzilmasi — haqiqiy huquqiy mazmun (prompt matni)
/// bu yerda yozilmaydi (Module 4, Phase 1 talabi).
///
/// **Nega Freezed emas:** `ai_service/` `lib/`dan (Flutter paketi
/// ildizidan) ataylab tashqarida joylashadi (`ai_service/README.md`ga
/// qarang), shuning uchun `build_runner`ning standart konfiguratsiyasi
/// bu papkani kodgen manbai sifatida ko'rmaydi. Bundan tashqari, bu
/// kod kelgusida boshqa (Flutter bo'lmagan) backend muhitiga
/// ko'chirilishi mo'ljallangan — Freezed/build_runner'ga bog'liq
/// bo'lmaslik uni ko'chirishni osonlashtiradi.
class AIMessage {
  const AIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final AIMessageRole role;
  final String content;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIMessage &&
            other.id == id &&
            other.role == role &&
            other.content == content &&
            other.createdAt == createdAt);
  }

  @override
  int get hashCode => Object.hash(id, role, content, createdAt);

  @override
  String toString() =>
      'AIMessage(id: $id, role: $role, content: $content, createdAt: $createdAt)';
}

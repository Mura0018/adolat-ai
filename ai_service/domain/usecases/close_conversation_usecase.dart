import '../entities/ai_conversation.dart';
import '../repositories/conversation_repository.dart';

/// Suhbatni yopadi (Module 4, Phase 2C talabi: "AI UseCases").
///
/// `ConversationRepository.close()` Phase 2A'dan beri mavjud edi,
/// lekin uni to'g'ri qatlam (usecase) orqali chaqirish uchun hech
/// qanday yo'l yo'q edi -- chaqiruvchi tomon to'g'ridan-to'g'ri
/// repository'ga murojaat qilishga majbur bo'lar edi, bu esa
/// orkestratsiya qatlamini (`presentation/ai_service_handler.dart`)
/// chetlab o'tar edi. Bu usecase shu bo'shliqni to'ldiradi.
class CloseConversationUseCase {
  const CloseConversationUseCase(this._conversationRepository);

  final ConversationRepository _conversationRepository;

  /// Tashlaydi: `ConversationNotFoundException` — suhbat topilmasa
  /// (`../repositories/conversation_exceptions.dart`).
  AIConversation call(String conversationId) {
    return _conversationRepository.close(conversationId);
  }
}

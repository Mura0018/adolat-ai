import '../repositories/conversation_repository.dart';

/// Yangi suhbat boshlaydi (Module 4, Phase 2C talabi: "AI UseCases").
///
/// `lib/features/*/domain/usecases/`dagi bir usecase-bir operatsiya
/// konventsiyasining `ai_service/`dagi ko'rinishi -- shu tufayli
/// `presentation/ai_service_handler.dart` (kirish nuqtasi) domain
/// qatlamini to'g'ridan-to'g'ri emas, faqat usecase orqali chaqiradi.
class StartConversationUseCase {
  const StartConversationUseCase(this._conversationRepository);

  final ConversationRepository _conversationRepository;

  String call() => _conversationRepository.create().id;
}

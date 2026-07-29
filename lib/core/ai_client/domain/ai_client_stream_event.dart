import '../../error/failure.dart';
import 'ai_client_message.dart';

/// `AiResponseMapper`ning chiqishi -- presentation qatlami (kelgusi chat
/// controller/UI) ko'radigan YAGONA oqim turi. `protocol/
/// ai_protocol_stream_event.dart` (simli, `AiProtocolError` olib yuradi)
/// bilan ADASHTIRILMASIN: bu klass DOMEN darajasida, xatoligi esa
/// ilovaning yagona, mavjud `Failure` turida (`core/error/failure.dart`)
/// -- AI-ga xos ikkinchi xatolik ierarxiyasi yo'q.
///
/// Presentation qatlami hech qachon `protocol/` papkasini to'g'ridan-
/// to'g'ri ko'rmasligi kerak -- shu ajratish orqali (`ai_service/`dagi
/// `AIStreamEvent` vs `AIProtocolStreamEvent` bilan bir xil naqsh,
/// endi klient tomonida).
sealed class AiClientStreamEvent {
  const AiClientStreamEvent();

  String get requestId;
  String get conversationId;
}

/// Backend so'rovni qabul qildi, oqim boshlanmoqda -- hali hech qanday
/// matn kelmagan. Presentation qatlami buni "yuklanmoqda" holatini
/// ko'rsatish uchun ishlatadi.
final class AiClientStreamStarted extends AiClientStreamEvent {
  const AiClientStreamStarted({required this.requestId, required this.conversationId});

  @override
  final String requestId;
  @override
  final String conversationId;
}

/// Qisman (delta) matn bo'lagi.
final class AiClientStreamChunk extends AiClientStreamEvent {
  const AiClientStreamChunk({
    required this.requestId,
    required this.conversationId,
    required this.sequence,
    required this.deltaContent,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final int sequence;
  final String deltaContent;
}

/// Oqim muvaffaqiyatli yakunlandi -- to'liq assistant xabari bilan.
final class AiClientStreamCompleted extends AiClientStreamEvent {
  const AiClientStreamCompleted({
    required this.requestId,
    required this.conversationId,
    required this.message,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final AiClientMessage message;
}

/// Bekor qilindi -- xatolik emas, ataylab to'xtatilgan holat.
final class AiClientStreamCancelled extends AiClientStreamEvent {
  const AiClientStreamCancelled({required this.requestId, required this.conversationId});

  @override
  final String requestId;
  @override
  final String conversationId;
}

/// Xatolik bilan yakunlandi -- ilovaning yagona `Failure` turi bilan
/// (`core/error/failure.dart`). `failure.userMessage`
/// (`core/error/failure_presentation.dart`) UI'da xavfsiz ko'rsatish
/// uchun ishlatiladi -- boshqa har qanday `Failure` bilan bir xil yo'l.
final class AiClientStreamFailed extends AiClientStreamEvent {
  const AiClientStreamFailed({
    required this.requestId,
    required this.conversationId,
    required this.failure,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final Failure failure;
}

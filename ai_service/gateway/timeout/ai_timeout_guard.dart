import '../../domain/entities/ai_failure.dart';
import '../../domain/entities/ai_stream_event.dart';
import 'ai_timeout_policy.dart';

/// `AITimeoutPolicy`ni haqiqiy `Stream<AIStreamEvent>` ustida ijro
/// etadi (Module 4, Phase 3B talabi: "Timeout Strategy").
///
/// Ichki `AIStreamEvent` darajasida ishlaydi (protokol -- `protocol/`
/// -- emas), shuning uchun natija `AITimeoutFailure` (`domain/entities/
/// ai_failure.dart`, Phase 2C'da allaqachon mavjud) bilan
/// `AIStreamEventError` sifatida chiqadi -- keyinroq
/// `gateway/dispatch/ai_response_dispatcher.dart` buni boshqa har
/// qanday ichki xatolik kabi, bir xil yo'l bilan `AIProtocolError`ga
/// tarjima qiladi. Alohida "timeout hodisasi" turini ixtiro qilish
/// shart emas -- muddat tugashi ham, oddiy, allaqachon mavjud xatolik
/// turi.
class AITimeoutGuard {
  const AITimeoutGuard(this._policy);

  final AITimeoutPolicy _policy;

  Stream<AIStreamEvent> guard(Stream<AIStreamEvent> events) {
    return events.timeout(
      _policy.eventTimeout,
      onTimeout: (sink) {
        sink.add(const AIStreamEventError(failure: AITimeoutFailure()));
        sink.close();
      },
    );
  }
}

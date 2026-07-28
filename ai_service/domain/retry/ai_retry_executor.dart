import '../entities/ai_stream_event.dart';
import 'ai_retry_policy.dart';

/// `AIRetryPolicy` qoidasini haqiqiy oqim (stream) operatsiyasi ustida
/// ijro etadi (Module 4, Phase 2C talabi: "Retry abstraction").
///
/// **Streaming-xavfsiz qayta urinish qoidasi:** agar operatsiya
/// hech bo'lmasa bitta `AIStreamEventChunk` chiqarib ulgurgan bo'lsa,
/// xatolik bilan tugasa ham QAYTA URINILMAYDI -- chunki tinglovchi
/// allaqachon qisman javobni ko'rgan, urinishni boshidan takrorlash
/// oldingi bo'laklarni QAYTA yuborib, javobni ikki marta
/// ko'paytirib/aralashtirib yuboradi. Qayta urinish faqat "butun
/// urinish HECH NARSA chiqarmasdan muvaffaqiyatsiz bo'ldi" holatida
/// mantiqan xavfsiz (masalan ulanish o'rnatilmadi).
///
/// Provayder yoki tarmoqqa hech qanday bog'liqlik yo'q -- istalgan
/// `Stream<AIStreamEvent> Function()` operatsiyasini o'rab oladi,
/// shuning uchun `domain/`da (sof Dart, tashqi paketsiz) qoladi.
class AIRetryExecutor {
  const AIRetryExecutor(this._policy);

  final AIRetryPolicy _policy;

  Stream<AIStreamEvent> run(Stream<AIStreamEvent> Function() operation) async* {
    var attempt = 1;

    while (true) {
      AIStreamEventError? lastError;
      var emittedAnyChunk = false;

      await for (final event in operation()) {
        switch (event) {
          case AIStreamEventChunk():
            emittedAnyChunk = true;
            yield event;
          case AIStreamEventError():
            lastError = event;
          case AIStreamEventDone() || AIStreamEventCancelled():
            yield event;
        }
      }

      if (lastError == null) return; // Xatoliksiz yakunlandi.

      final canRetry =
          !emittedAnyChunk &&
          _policy.shouldRetry(failure: lastError.failure, attemptNumber: attempt);

      if (!canRetry) {
        yield lastError;
        return;
      }

      await Future<void>.delayed(_policy.delayForAttempt(attempt));
      attempt += 1;
    }
  }
}

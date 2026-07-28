import '../entities/ai_failure.dart';

/// Nechta marta va qancha kutib qayta urinish kerakligini belgilaydigan
/// sof konfiguratsiya (policy) klassi (Module 4, Phase 2C talabi:
/// "Retry abstraction").
///
/// **Faqat qoida, ijro emas:** bu klass HECH QANDAY operatsiyani o'zi
/// bajarmaydi -- shunchaki "nechinchi urinishda qancha kutish kerak"
/// va "shu xatolik uchun umuman qayta urinish kerakmi" savollariga
/// javob beradi. Haqiqiy ijro `AIRetryExecutor`da
/// (`ai_retry_executor.dart`).
///
/// `ADR-005`da qayd etilgan "cheklangan sonli avtomatik qayta
/// urinishdan keyin aniq xatolik holati belgilanadi" talabining
/// arxitektura darajasidagi ifodasi.
class AIRetryPolicy {
  const AIRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
  }) : assert(maxAttempts >= 1, 'maxAttempts kamida 1 bo\'lishi kerak'),
       assert(
         backoffMultiplier >= 1.0,
         'backoffMultiplier 1.0dan kichik bo\'lmasligi kerak',
       );

  /// Jami urinishlar soni (birinchi urinish + qayta urinishlar).
  final int maxAttempts;

  /// Birinchi qayta urinishdan oldingi kutish vaqti.
  final Duration initialDelay;

  /// Har keyingi urinishda kutish vaqti shu koeffitsientga ko'payadi
  /// (eksponensial backoff).
  final double backoffMultiplier;

  /// `attemptNumber`-urinish (1-asosli) muvaffaqiyatsiz bo'lgandan
  /// keyin, keyingi urinishdan oldin qancha kutish kerakligini
  /// hisoblaydi.
  Duration delayForAttempt(int attemptNumber) {
    final scale = _pow(backoffMultiplier, attemptNumber - 1);
    return initialDelay * scale;
  }

  /// `attemptNumber`-urinish `failure` bilan muvaffaqiyatsiz bo'ldi --
  /// yana urinish kerakmi?
  ///
  /// Ikkala shart ham bajarilishi kerak: (1) xatolik turi o'zi
  /// qayta urinishga mos (`AIFailure.isRetryable`), va (2) limit
  /// hali tugamagan.
  bool shouldRetry({required AIFailure failure, required int attemptNumber}) {
    if (attemptNumber >= maxAttempts) return false;
    return failure.isRetryable;
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

/// Oqimdagi ikkita ketma-ket hodisa orasidagi (yoki oqim
/// boshlanishidan birinchi hodisagacha) maksimal kutish vaqti (Module
/// 4, Phase 3B talabi: "Timeout Strategy").
///
/// `AIRetryPolicy` (`domain/retry/`, Phase 2C) bilan bir xil ruhda --
/// sof konfiguratsiya, hech qanday ijro mantig'i yo'q (ijro --
/// `AITimeoutGuard`da). Bitta `eventTimeout` ishlatilgan (ikkita
/// alohida "birinchi hodisa"/"keyingi hodisalar" chegarasi emas) --
/// bu aynan Dart'ning o'zining `Stream.timeout()` semantikasi
/// (`AITimeoutGuard`ga qarang), shuning uchun ijro qismi ustiga
/// hech qanday qo'shimcha, xato qilish ehtimoli yuqori mantiq
/// qurilmaydi.
class AITimeoutPolicy {
  const AITimeoutPolicy({this.eventTimeout = const Duration(seconds: 30)});

  final Duration eventTimeout;
}

import 'failure.dart';

/// `Failure`ni foydalanuvchiga **xavfsiz** ko'rsatish uchun kengaytma.
///
/// docs/SECURITY.md, "API Security" bo'limi: "API xatoliklari
/// foydalanuvchiga ichki tizim tafsilotlarini (masalan, DB struktura,
/// stack trace) oshkor qilmaydigan umumiy shaklda ko'rsatiladi." Shu
/// sababli bu yerda qaytariladigan matn **hech qachon** backend'dan
/// kelgan xom xabar (`ServerFailure.message`, `StorageFailure.message`
/// va h.k.) ni o'z ichiga olmaydi — faqat oldindan yozilgan, umumiy,
/// foydalanuvchiga tushunarli matn.
///
/// Istisno — `ValidationFailure`: uning `message`si backend'dan emas,
/// ilovaning o'zidan (masalan forma validatsiyasidan) keladi, shuning
/// uchun to'g'ridan-to'g'ri ko'rsatish xavfsiz.
///
/// Diagnostika uchun xom xabar hali ham `Failure` obyektining o'zida
/// saqlanadi (masalan loglash uchun, `services/supabase/
/// supabase_exception_mapper.dart`da `kDebugMode`da bosiladi) — faqat
/// UI'ga chiqarilmaydi.
extension FailureUserMessage on Failure {
  String get userMessage => switch (this) {
    NetworkFailure() =>
      'Internet aloqasi yo\'q yoki uzilib qoldi. Iltimos, aloqani '
          'tekshirib, qayta urinib ko\'ring.',
    ServerFailure() =>
      'Server bilan bog\'lanishda xatolik yuz berdi. Iltimos, '
          'birozdan so\'ng qayta urinib ko\'ring.',
    PermissionDeniedFailure() => 'Bu amalni bajarishga ruxsatingiz yo\'q.',
    ValidationFailure(:final message) => message,
    StorageFailure() =>
      'Fayl bilan ishlashda xatolik yuz berdi. Iltimos, qayta urinib '
          'ko\'ring.',
    UnknownFailure() =>
      'Kutilmagan xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.',
  };
}

/// `AsyncValue.when`/`whenOrNull`ning `error` chaqiruvchisi kabi
/// statik turi `Object` bo'lgan joylarda ishlatish uchun xavfsiz
/// yordamchi. `Result<T>` konventsiyasiga rioya qilingan har qanday
/// oqimda bu obyekt amalda har doim `Failure` bo'ladi (providerlar
/// `throw failure;` qiladi — `core/network/result.dart`ga qarang), lekin
/// kelajakda tasodifan boshqa turdagi exception "sizib chiqsa" ham UI
/// baribir xom matnni ko'rsatmasligi uchun himoyalangan.
String describeErrorForUser(Object error) {
  if (error is Failure) return error.userMessage;
  return 'Kutilmagan xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.';
}

import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/core/network/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// `Result<T>`/`Failure` ustidagi umumiy matcher'lar va yordamchilar
/// (`test/features/` infratuzilmasi, 2026-07-30 auditi, 2-topilma).
///
/// **Nega kerak:** `Result` -- `sealed` union, shuning uchun har bir
/// testda `switch`/`is ResultError<T>` yozish kod takrorlanishiga olib
/// keladi (`DEVELOPMENT_RULES.md`, 7-band). Bu fayl repository
/// qatlamidagi barcha testlar uchun yagona tasdiqlash (assertion)
/// tilini beradi.

/// Muvaffaqiyatli natijaning ma'lumotini qaytaradi, xatolik bo'lsa
/// testni ANIQ xabar bilan yiqitadi.
T expectOk<T>(Result<T> result) {
  switch (result) {
    case ResultOk<T>(:final data):
      return data;
    case ResultError<T>(:final failure):
      fail('Result.ok kutilgan edi, lekin Result.error keldi: $failure');
  }
}

/// Xatolik natijasining `Failure`ini qaytaradi, muvaffaqiyat bo'lsa
/// testni yiqitadi.
Failure expectFailure<T>(Result<T> result) {
  switch (result) {
    case ResultOk<T>(:final data):
      fail('Result.error kutilgan edi, lekin Result.ok keldi: $data');
    case ResultError<T>(:final failure):
      return failure;
  }
}

/// Xatolik natijasi AYNAN [F] turidagi `Failure` ekanligini tekshiradi
/// va uni qaytaradi.
///
/// Tur muhim: `docs/ARCHITECTURE.md`dagi `Exception → Failure`
/// konventsiyasi va `failure_presentation.dart`dagi foydalanuvchi
/// xabari aynan `Failure` TURIGA qarab tanlanadi -- noto'g'ri tur
/// foydalanuvchiga noto'g'ri keyingi qadam ko'rsatadi
/// (`DEVELOPMENT_RULES.md`, 17-band, "No Dead End Rule").
F expectFailureOfType<T, F extends Failure>(Result<T> result) {
  final failure = expectFailure(result);
  expect(
    failure,
    isA<F>(),
    reason: '$F turidagi Failure kutilgan edi, lekin ${failure.runtimeType} keldi',
  );
  return failure as F;
}

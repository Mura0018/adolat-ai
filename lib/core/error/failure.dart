import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Butun ilova bo'ylab ishlatiladigan xatolik shartnomasi.
///
/// Konventsiya (docs/ARCHITECTURE.md, "Ichki Kod Arxitekturasi"): `data`
/// qatlami xom `Exception` tashlaydi → `repository` implementatsiyasi uni
/// ushlab shu `Failure`ga aylantiradi va `Result<T>` (`core/network/result.dart`)
/// ichida qaytaradi → `domain`/`presentation` hech qachon xom exception
/// bilan ishlamaydi, faqat shu tuzilgan `Failure` bilan.
@freezed
sealed class Failure with _$Failure {
  /// Tarmoq aloqasi yo'q yoki uzilib qoldi (offline holat).
  const factory Failure.network({String? message}) = NetworkFailure;

  /// Backend (Supabase Postgrest/Storage/Auth) xatolik qaytardi.
  const factory Failure.server({required String message, String? code}) =
      ServerFailure;

  /// So'ralgan yozuvga kirish RLS tomonidan rad etildi.
  const factory Failure.permissionDenied({String? message}) =
      PermissionDeniedFailure;

  /// Foydalanuvchi kiritgan ma'lumot yaroqsiz (masalan majburiy maydon bo'sh).
  const factory Failure.validation({required String message}) =
      ValidationFailure;

  /// Fayl yuklash/Storage bilan bog'liq xatolik.
  const factory Failure.storage({required String message}) = StorageFailure;

  /// Yuqoridagilarga mos kelmaydigan, kutilmagan xatolik.
  const factory Failure.unknown({String? message}) = UnknownFailure;
}

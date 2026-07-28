import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/failure.dart';

part 'result.freezed.dart';

/// `repository` qatlamining standart qaytish turi.
///
/// `data` qatlamidagi exception `repository` implementatsiyasida ushlanadi
/// va `Failure`ga aylantirilib shu `Result`ning `Error` varianti sifatida
/// qaytariladi — `domain`/`presentation` hech qachon `try/catch` bilan xom
/// exception kutmaydi, faqat shu ikkita variantni pattern-match qiladi.
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T data) = ResultOk<T>;
  const factory Result.error(Failure failure) = ResultError<T>;
}

/// `Result<T>` ustida qulay kengaytmalar.
extension ResultX<T> on Result<T> {
  bool get isOk => this is ResultOk<T>;

  bool get isError => this is ResultError<T>;

  T? get dataOrNull => switch (this) {
    ResultOk<T>(:final data) => data,
    ResultError<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    ResultOk<T>() => null,
    ResultError<T>(:final failure) => failure,
  };
}

import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/core/network/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result<T>', () {
    test('ok variant reports isOk/isError correctly', () {
      const result = Result<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isError, isFalse);
    });

    test('error variant reports isOk/isError correctly', () {
      const result = Result<int>.error(Failure.network());

      expect(result.isOk, isFalse);
      expect(result.isError, isTrue);
    });

    test('dataOrNull returns the value for ok, null for error', () {
      const ok = Result<String>.ok('murojaat');
      const error = Result<String>.error(Failure.unknown());

      expect(ok.dataOrNull, 'murojaat');
      expect(error.dataOrNull, isNull);
    });

    test('failureOrNull returns null for ok, the failure for error', () {
      const failure = Failure.validation(message: 'Sarlavha kiritilishi shart');
      const ok = Result<String>.ok('murojaat');
      const error = Result<String>.error(failure);

      expect(ok.failureOrNull, isNull);
      expect(error.failureOrNull, failure);
    });
  });
}

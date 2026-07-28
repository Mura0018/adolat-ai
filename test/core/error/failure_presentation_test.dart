import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/core/error/failure_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureUserMessage', () {
    // docs/SECURITY.md, "API Security": foydalanuvchiga hech qachon xom
    // backend xabari (DB struktura, stack trace) ko'rsatilmasligi shart.
    test('server failure never leaks the raw backend message', () {
      const failure = Failure.server(
        message: 'relation "profiles" does not exist at line 42',
        code: 'PGRST116',
      );

      expect(failure.userMessage, isNot(contains('relation')));
      expect(failure.userMessage, isNot(contains('PGRST116')));
    });

    test('storage failure never leaks the raw backend message', () {
      const failure = Failure.storage(message: 'bucket policy denied: xyz');

      expect(failure.userMessage, isNot(contains('bucket policy')));
    });

    // Validation is the one variant whose message originates from the app
    // itself (form validation), not the backend — safe to show as-is.
    test('validation failure passes its own message through unchanged', () {
      const failure = Failure.validation(message: 'Sarlavha kiritilishi shart');

      expect(failure.userMessage, 'Sarlavha kiritilishi shart');
    });

    test('every Failure variant produces a non-empty user message', () {
      const failures = <Failure>[
        Failure.network(),
        Failure.server(message: 'x'),
        Failure.permissionDenied(),
        Failure.validation(message: 'x'),
        Failure.storage(message: 'x'),
        Failure.unknown(),
      ];

      for (final failure in failures) {
        expect(failure.userMessage, isNotEmpty);
      }
    });
  });

  group('describeErrorForUser', () {
    test('returns the Failure.userMessage when given a Failure', () {
      const failure = Failure.permissionDenied();

      expect(describeErrorForUser(failure), failure.userMessage);
    });

    // Defensive path: if a non-Failure exception ever leaks through, the
    // UI must still never show its raw toString().
    test('never leaks a raw exception message for a non-Failure error', () {
      final rawError = Exception('SELECT * FROM auth.users failed');

      expect(describeErrorForUser(rawError), isNot(contains('auth.users')));
    });
  });
}

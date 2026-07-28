import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_protocol_error.dart';

void main() {
  group('AIProtocolError', () {
    test('round-trips through JSON', () {
      const error = AIProtocolError(
        code: AIProtocolErrorCode.rateLimited,
        message: 'Juda ko\'p so\'rov yuborildi',
        retryable: true,
      );

      final decoded = AIProtocolError.fromJson(error.toJson());

      expect(decoded, error);
    });

    test('every error code round-trips by name', () {
      for (final code in AIProtocolErrorCode.values) {
        final error = AIProtocolError(code: code, message: 'x', retryable: false);

        final decoded = AIProtocolError.fromJson(error.toJson());

        expect(decoded.code, code);
      }
    });
  });
}

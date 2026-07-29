import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/gateway/validation/ai_response_validation_contract.dart';

void main() {
  group('AIResponseViolation', () {
    test('round-trips through JSON', () {
      const violation = AIResponseViolation(
        code: AIResponseViolationCode.negativeLatency,
        field: 'latencyMs',
        detail: 'latencyMs manfiy',
      );

      final decoded = AIResponseViolation.fromJson(violation.toJson());

      expect(decoded, violation);
    });

    test('every violation code round-trips by name', () {
      for (final code in AIResponseViolationCode.values) {
        final violation = AIResponseViolation(code: code, field: 'x', detail: 'x');

        final decoded = AIResponseViolation.fromJson(violation.toJson());

        expect(decoded.code, code);
      }
    });
  });

  group('AIResponseValidationResult', () {
    test('valid constant has no violations and isValid is true', () {
      expect(AIResponseValidationResult.valid.isValid, isTrue);
    });

    test('isValid is false when there is at least one violation', () {
      const result = AIResponseValidationResult(
        violations: [
          AIResponseViolation(
            code: AIResponseViolationCode.inconsistentTokenUsage,
            field: 'tokenUsage',
            detail: 'x',
          ),
        ],
      );

      expect(result.isValid, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/gateway/validation/ai_request_validation_contract.dart';

void main() {
  group('AIRequestViolation', () {
    test('round-trips through JSON', () {
      const violation = AIRequestViolation(
        code: AIRequestViolationCode.messageTooLong,
        field: 'message',
        detail: 'Xabar juda uzun',
      );

      final decoded = AIRequestViolation.fromJson(violation.toJson());

      expect(decoded, violation);
    });

    test('every violation code round-trips by name', () {
      for (final code in AIRequestViolationCode.values) {
        final violation = AIRequestViolation(code: code, field: 'x', detail: 'x');

        final decoded = AIRequestViolation.fromJson(violation.toJson());

        expect(decoded.code, code);
      }
    });
  });

  group('AIRequestValidationResult', () {
    test('valid constant has no violations and isValid is true', () {
      expect(AIRequestValidationResult.valid.isValid, isTrue);
      expect(AIRequestValidationResult.valid.violations, isEmpty);
    });

    test('isValid is false when there is at least one violation', () {
      const result = AIRequestValidationResult(
        violations: [
          AIRequestViolation(
            code: AIRequestViolationCode.messageEmpty,
            field: 'message',
            detail: 'Xabar bo\'sh',
          ),
        ],
      );

      expect(result.isValid, isFalse);
    });

    test('equality compares violations element-wise', () {
      const a = AIRequestValidationResult(
        violations: [
          AIRequestViolation(
            code: AIRequestViolationCode.tooManyAttachments,
            field: 'attachments',
            detail: 'x',
          ),
        ],
      );
      const b = AIRequestValidationResult(
        violations: [
          AIRequestViolation(
            code: AIRequestViolationCode.tooManyAttachments,
            field: 'attachments',
            detail: 'x',
          ),
        ],
      );

      expect(a, b);
    });
  });
}

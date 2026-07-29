import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/accounting/ai_token_accounting.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';

void main() {
  group('AITokenAccountingEntry.fromRawUsage', () {
    test('computes cost from prompt/completion token rates', () {
      const rate = AITokenCostRate(
        providerId: AIProviderId.openAI,
        currency: 'USD',
        costPerThousandPromptTokens: 1.0,
        costPerThousandCompletionTokens: 2.0,
      );

      final entry = AITokenAccountingEntry.fromRawUsage(
        conversationId: 'conv1',
        requestId: 'req1',
        providerId: AIProviderId.openAI,
        promptTokens: 1000,
        completionTokens: 500,
        rate: rate,
        recordedAt: DateTime(2026, 1, 1),
      );

      expect(entry.estimatedCost, 1.0 + 1.0);
      expect(entry.currency, 'USD');
      expect(entry.totalTokens, 1500);
    });

    test('zero tokens produce zero cost', () {
      const rate = AITokenCostRate(
        providerId: AIProviderId.gemini,
        currency: 'USD',
        costPerThousandPromptTokens: 5.0,
        costPerThousandCompletionTokens: 5.0,
      );

      final entry = AITokenAccountingEntry.fromRawUsage(
        conversationId: 'conv1',
        requestId: 'req1',
        providerId: AIProviderId.gemini,
        promptTokens: 0,
        completionTokens: 0,
        rate: rate,
        recordedAt: DateTime(2026, 1, 1),
      );

      expect(entry.estimatedCost, 0);
    });

    test('asserts that the rate provider matches the usage provider', () {
      const rate = AITokenCostRate(
        providerId: AIProviderId.claude,
        currency: 'USD',
        costPerThousandPromptTokens: 1.0,
        costPerThousandCompletionTokens: 1.0,
      );

      expect(
        () => AITokenAccountingEntry.fromRawUsage(
          conversationId: 'conv1',
          requestId: 'req1',
          providerId: AIProviderId.openAI,
          promptTokens: 10,
          completionTokens: 10,
          rate: rate,
          recordedAt: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AITokenCostRate', () {
    test('rejects negative rates', () {
      expect(
        () => AITokenCostRate(
          providerId: AIProviderId.local,
          currency: 'USD',
          costPerThousandPromptTokens: -1,
          costPerThousandCompletionTokens: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

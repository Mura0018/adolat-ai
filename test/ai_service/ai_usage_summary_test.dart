import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_usage_summary.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';

void main() {
  group('AIUsageSummary', () {
    test('round-trips through JSON', () {
      final summary = AIUsageSummary(
        providerId: AIProviderId.gemini,
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 2),
        totalRequests: 42,
        totalPromptTokens: 1000,
        totalCompletionTokens: 500,
        totalCost: 3.5,
        currency: 'USD',
      );

      final decoded = AIUsageSummary.fromJson(summary.toJson());

      expect(decoded, summary);
    });

    test('totalTokens sums prompt and completion tokens', () {
      final summary = AIUsageSummary(
        providerId: AIProviderId.gemini,
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 2),
        totalRequests: 1,
        totalPromptTokens: 1000,
        totalCompletionTokens: 500,
        totalCost: 0,
        currency: 'USD',
      );

      expect(summary.totalTokens, 1500);
    });

    test('rejects negative totals', () {
      expect(
        () => AIUsageSummary(
          providerId: AIProviderId.gemini,
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 2),
          totalRequests: -1,
          totalPromptTokens: 0,
          totalCompletionTokens: 0,
          totalCost: 0,
          currency: 'USD',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

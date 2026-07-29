import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_provider_cost_control.dart';

void main() {
  group('AIProviderCostControlParams', () {
    test('round-trips through JSON', () {
      const params = AIProviderCostControlParams(
        dailyBudget: 50,
        monthlyBudget: 1000,
        currency: 'USD',
        alertThresholdRatio: 0.8,
      );

      final decoded = AIProviderCostControlParams.fromJson(params.toJson());

      expect(decoded, params);
    });

    test('rejects a non-positive dailyBudget', () {
      expect(
        () => AIProviderCostControlParams(
          dailyBudget: 0,
          monthlyBudget: 1000,
          currency: 'USD',
          alertThresholdRatio: 0.8,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive monthlyBudget', () {
      expect(
        () => AIProviderCostControlParams(
          dailyBudget: 50,
          monthlyBudget: 0,
          currency: 'USD',
          alertThresholdRatio: 0.8,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an alertThresholdRatio outside (0, 1]', () {
      expect(
        () => AIProviderCostControlParams(
          dailyBudget: 50,
          monthlyBudget: 1000,
          currency: 'USD',
          alertThresholdRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AIProviderCostControlParams(
          dailyBudget: 50,
          monthlyBudget: 1000,
          currency: 'USD',
          alertThresholdRatio: 1.1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts an alertThresholdRatio of exactly 1', () {
      const params = AIProviderCostControlParams(
        dailyBudget: 50,
        monthlyBudget: 1000,
        currency: 'USD',
        alertThresholdRatio: 1,
      );

      expect(params.alertThresholdRatio, 1);
    });
  });
}

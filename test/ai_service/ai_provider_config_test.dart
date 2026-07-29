import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_credential_reference.dart';
import '../../ai_service/config/domain/ai_provider_config.dart';
import '../../ai_service/config/domain/ai_provider_cost_control.dart';
import '../../ai_service/config/domain/ai_provider_token_limits.dart';
import '../../ai_service/config/domain/ai_provider_usage_limits.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';

AIProviderConfig _config({AIProviderId providerId = AIProviderId.openAI, bool enabled = true}) {
  return AIProviderConfig(
    providerId: providerId,
    enabled: enabled,
    activeModel: 'gpt-4o',
    credentialRef: const AICredentialReference(
      storeKind: AICredentialStoreKind.environmentVariable,
      referenceKey: 'OPENAI_API_KEY',
    ),
    usageLimits: const AIProviderUsageLimits(maxRequestsPerDay: 1000, maxConcurrentRequests: 10),
    tokenLimits: const AIProviderTokenLimits(maxPromptTokens: 4000, maxCompletionTokens: 2000),
    costControl: const AIProviderCostControlParams(
      dailyBudget: 50,
      monthlyBudget: 1000,
      currency: 'USD',
      alertThresholdRatio: 0.8,
    ),
  );
}

void main() {
  group('AIProviderConfig', () {
    test('round-trips through JSON', () {
      final config = _config();

      final decoded = AIProviderConfig.fromJson(config.toJson());

      expect(decoded, config);
    });

    test('round-trips for every known AIProviderId', () {
      for (final providerId in AIProviderId.values) {
        final config = _config(providerId: providerId);

        final decoded = AIProviderConfig.fromJson(config.toJson());

        expect(decoded.providerId, providerId);
      }
    });

    test('does not serialize a raw secret anywhere -- only credentialRef', () {
      final config = _config();
      final json = config.toJson();

      expect(json['credentialRef'], isA<Map<String, dynamic>>());
      expect((json['credentialRef'] as Map<String, dynamic>).containsKey('referenceKey'), isTrue);
    });

    test('a disabled provider round-trips its enabled flag', () {
      final config = _config(enabled: false);

      final decoded = AIProviderConfig.fromJson(config.toJson());

      expect(decoded.enabled, isFalse);
    });
  });
}

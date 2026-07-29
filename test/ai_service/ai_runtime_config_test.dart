import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_credential_reference.dart';
import '../../ai_service/config/domain/ai_provider_config.dart';
import '../../ai_service/config/domain/ai_provider_cost_control.dart';
import '../../ai_service/config/domain/ai_provider_token_limits.dart';
import '../../ai_service/config/domain/ai_provider_usage_limits.dart';
import '../../ai_service/config/runtime/ai_runtime_config.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';

AIProviderConfig _config({required AIProviderId providerId, required bool enabled}) {
  return AIProviderConfig(
    providerId: providerId,
    enabled: enabled,
    activeModel: 'model-x',
    credentialRef: const AICredentialReference(
      storeKind: AICredentialStoreKind.environmentVariable,
      referenceKey: 'X_API_KEY',
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
  group('AIRuntimeConfig', () {
    test('isEnabled reflects each provider\'s enabled flag', () {
      final config = AIRuntimeConfig(
        providerConfigs: {
          AIProviderId.openAI: _config(providerId: AIProviderId.openAI, enabled: true),
          AIProviderId.gemini: _config(providerId: AIProviderId.gemini, enabled: false),
        },
        loadedAt: DateTime(2026, 1, 1),
      );

      expect(config.isEnabled(AIProviderId.openAI), isTrue);
      expect(config.isEnabled(AIProviderId.gemini), isFalse);
    });

    test('isEnabled is false for a provider with no configuration at all', () {
      final config = AIRuntimeConfig(providerConfigs: const {}, loadedAt: DateTime(2026, 1, 1));

      expect(config.isEnabled(AIProviderId.claude), isFalse);
    });

    test('enabledProviderIds yields only the enabled providers', () {
      final config = AIRuntimeConfig(
        providerConfigs: {
          AIProviderId.openAI: _config(providerId: AIProviderId.openAI, enabled: true),
          AIProviderId.gemini: _config(providerId: AIProviderId.gemini, enabled: false),
          AIProviderId.claude: _config(providerId: AIProviderId.claude, enabled: true),
        },
        loadedAt: DateTime(2026, 1, 1),
      );

      expect(
        config.enabledProviderIds.toSet(),
        {AIProviderId.openAI, AIProviderId.claude},
      );
    });
  });
}

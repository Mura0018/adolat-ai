import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_credential_reference.dart';
import '../../ai_service/config/domain/ai_provider_config.dart';
import '../../ai_service/config/domain/ai_provider_cost_control.dart';
import '../../ai_service/config/domain/ai_provider_token_limits.dart';
import '../../ai_service/config/domain/ai_provider_usage_limits.dart';
import '../../ai_service/config/runtime/ai_credential_resolver.dart';
import '../../ai_service/config/runtime/ai_runtime_config.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/di/ai_service_locator.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_request.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/gateway/auth/ai_auth_context.dart';
import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';
import '../../ai_service/safety/ai_safety_check_result.dart';
import '../../ai_service/safety/ai_safety_service.dart';

class _AlwaysSafe implements AISafetyService {
  @override
  Future<AISafetyCheckResult> validateRequest(AIRequest request) async =>
      const AISafetyCheckResult(isSafe: true);

  @override
  Future<AISafetyCheckResult> validateResponse(AIResponse response) async =>
      const AISafetyCheckResult(isSafe: true);
}

class _FakeCredentialResolver implements AICredentialResolver {
  final List<AICredentialReference> resolvedReferences = [];

  @override
  Future<String> resolve(AICredentialReference reference) async {
    resolvedReferences.add(reference);
    return 'resolved:${reference.referenceKey}';
  }
}

AIProviderConfig _providerConfig({required AIProviderId providerId, required bool enabled}) {
  return AIProviderConfig(
    providerId: providerId,
    enabled: enabled,
    activeModel: 'model-x',
    credentialRef: AICredentialReference(
      storeKind: AICredentialStoreKind.environmentVariable,
      referenceKey: '${providerId.name}_API_KEY',
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
  group('AIServiceLocator.build -- Phase 4C pluggable composition root', () {
    test('uses the injected conversationRepository instead of a fresh in-memory one', () {
      final customRepository = InMemoryConversationRepository();
      final handler = AIServiceLocator.build(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
        conversationRepository: customRepository,
      );

      final conversationId = handler.startConversation();

      expect(customRepository.getById(conversationId), isNotNull);
    });

    test('falls back to an in-memory conversationRepository when none is injected', () {
      final handler = AIServiceLocator.build(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
      );

      expect(handler.startConversation(), isNotEmpty);
    });
  });

  group('AIServiceLocator.buildGateway -- Phase 4C pluggable composition root', () {
    test('uses the injected conversationRepository -- request reaches provider selection, not conversationNotFound', () async {
      final customRepository = InMemoryConversationRepository();
      final conversation = customRepository.create();

      final gateway = AIServiceLocator.buildGateway(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
        selectProvider: (_) => AIProviderId.openAI,
        conversationRepository: customRepository,
      );

      final events = await gateway
          .handle(
            request: AIRequestEnvelope(
              requestId: 'req1',
              conversationId: conversation.id,
              userId: 'user1',
              message: 'hi',
              requestedAt: DateTime(2026, 1, 1),
            ),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
          )
          .toList();

      final failed = events.whereType<AIProtocolStreamEventFailed>().single;
      // providerCredentials is empty, so openAI has no adapter configured --
      // this (not conversationNotFound) proves the conversation was found
      // via the INJECTED repository before reaching provider dispatch.
      expect(failed.error.code, AIProtocolErrorCode.providerNotConfigured);
    });
  });

  group('AIServiceLocator.resolveProviderCredentials -- Phase 5A runtime configuration', () {
    test('resolves credentials only for enabled providers', () async {
      final resolver = _FakeCredentialResolver();
      final runtimeConfig = AIRuntimeConfig(
        providerConfigs: {
          AIProviderId.openAI: _providerConfig(providerId: AIProviderId.openAI, enabled: true),
          AIProviderId.gemini: _providerConfig(providerId: AIProviderId.gemini, enabled: false),
        },
        loadedAt: DateTime(2026, 1, 1),
      );

      final credentials = await AIServiceLocator.resolveProviderCredentials(
        runtimeConfig: runtimeConfig,
        credentialResolver: resolver,
      );

      expect(credentials.keys, [AIProviderId.openAI]);
      expect(credentials[AIProviderId.openAI], 'resolved:openAI_API_KEY');
      expect(resolver.resolvedReferences, hasLength(1));
    });

    test('returns an empty map when no providers are enabled', () async {
      final resolver = _FakeCredentialResolver();
      final runtimeConfig = AIRuntimeConfig(
        providerConfigs: {
          AIProviderId.openAI: _providerConfig(providerId: AIProviderId.openAI, enabled: false),
        },
        loadedAt: DateTime(2026, 1, 1),
      );

      final credentials = await AIServiceLocator.resolveProviderCredentials(
        runtimeConfig: runtimeConfig,
        credentialResolver: resolver,
      );

      expect(credentials, isEmpty);
      expect(resolver.resolvedReferences, isEmpty);
    });

    test('the resolved credentials feed directly into buildGateway()', () async {
      final resolver = _FakeCredentialResolver();
      final runtimeConfig = AIRuntimeConfig(
        providerConfigs: {
          AIProviderId.openAI: _providerConfig(providerId: AIProviderId.openAI, enabled: true),
        },
        loadedAt: DateTime(2026, 1, 1),
      );
      final customRepository = InMemoryConversationRepository();
      final conversation = customRepository.create();

      final credentials = await AIServiceLocator.resolveProviderCredentials(
        runtimeConfig: runtimeConfig,
        credentialResolver: resolver,
      );
      final gateway = AIServiceLocator.buildGateway(
        providerCredentials: credentials,
        safetyService: _AlwaysSafe(),
        selectProvider: (_) => AIProviderId.openAI,
        conversationRepository: customRepository,
      );

      // openAI now HAS a resolved credential (unlike the empty-map test
      // above), so the real (Phase 1 stub) OpenAiProviderAdapter is
      // actually constructed and reached -- it throws UnimplementedError
      // rather than the gateway short-circuiting with providerNotConfigured.
      // This proves resolveProviderCredentials()'s output was actually
      // wired into buildGateway(), not just computed and discarded.
      await expectLater(
        gateway
            .handle(
              request: AIRequestEnvelope(
                requestId: 'req1',
                conversationId: conversation.id,
                userId: 'user1',
                message: 'hi',
                requestedAt: DateTime(2026, 1, 1),
              ),
              auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
            )
            .toList(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}

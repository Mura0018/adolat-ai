import 'package:adolat_ai/core/ai_client/context/ai_client_case_context.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_context_assembler.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_safety_context.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_system_context.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_user_context.dart';
import 'package:adolat_ai/features/attachments/domain/entities/case_type.dart';
import 'package:adolat_ai/features/auth/domain/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiClientContextAssembler', () {
    const systemContext = AiClientSystemContext(locale: 'uz');
    const userContext = AiClientUserContext(role: UserRole.citizen, preferredLanguage: 'uz');
    const safetyContext = AiClientSafetyContext(requiresImpartiality: true);

    test('assembles mandatory contexts under their wire keys', () {
      const assembler = AiClientContextAssembler(
        systemContext: systemContext,
        userContext: userContext,
        safetyContext: safetyContext,
      );

      final result = assembler.assemble();

      expect(result.keys, containsAll(['system', 'user', 'safety']));
      expect(result['system'], {'locale': 'uz', 'response_mode': 'default'});
      expect(result['user'], {'role': 'citizen', 'preferred_language': 'uz'});
      expect(result['safety'], {'requires_impartiality': true});
    });

    test('optional contexts are absent from the map when not provided', () {
      const assembler = AiClientContextAssembler(
        systemContext: systemContext,
        userContext: userContext,
        safetyContext: safetyContext,
      );

      final result = assembler.assemble();

      expect(result.containsKey('case'), isFalse);
      expect(result.containsKey('memory'), isFalse);
    });

    test('case context is included when provided, keyed by dbValue', () {
      const assembler = AiClientContextAssembler(
        systemContext: systemContext,
        userContext: userContext,
        safetyContext: safetyContext,
        caseContext: AiClientCaseContext(caseType: CaseType.dispute, disputeId: 'd1'),
      );

      final result = assembler.assemble();

      expect(result['case'], {'case_type': 'dispute', 'dispute_id': 'd1'});
    });
  });
}

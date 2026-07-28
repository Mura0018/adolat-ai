import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/prompt/ai_case_type.dart';
import '../../ai_service/domain/prompt/ai_user_role.dart';
import '../../ai_service/domain/prompt/case_context.dart';
import '../../ai_service/domain/prompt/context_assembler.dart';
import '../../ai_service/domain/prompt/memory_context.dart';
import '../../ai_service/domain/prompt/safety_context.dart';
import '../../ai_service/domain/prompt/system_context.dart';
import '../../ai_service/domain/prompt/user_context.dart';

void main() {
  group('ContextAssembler', () {
    test('assembles only the required contexts when optional ones are omitted', () {
      const assembler = ContextAssembler(
        systemContext: SystemContext(locale: 'uz'),
        userContext: UserContext(
          role: AIUserRole.citizen,
          preferredLanguage: 'uz',
        ),
        safetyContext: SafetyContext(),
      );

      final context = assembler.assemble();

      expect(context.sections.keys, {'system', 'user', 'safety'});
      expect(context.sectionFor('case'), isNull);
      expect(context.sectionFor('memory'), isNull);
    });

    test('includes optional contexts when provided', () {
      const assembler = ContextAssembler(
        systemContext: SystemContext(locale: 'uz'),
        userContext: UserContext(
          role: AIUserRole.organization,
          preferredLanguage: 'uz',
        ),
        safetyContext: SafetyContext(requiresImpartiality: true),
        caseContext: CaseContext(
          caseType: AICaseType.dispute,
          disputeId: 'd1',
        ),
        memoryContext: MemoryContext(summarizedHistory: ['prior turn']),
      );

      final context = assembler.assemble();

      expect(
        context.sections.keys,
        {'system', 'user', 'safety', 'case', 'memory'},
      );
      expect(context.sectionFor('case'), {
        'case_type': 'dispute',
        'dispute_id': 'd1',
      });
      expect(context.sectionFor('memory'), {
        'summarized_history': ['prior turn'],
      });
    });

    test(
      'assembling twice with equal inputs produces equal AIContext instances',
      () {
        const assembler = ContextAssembler(
          systemContext: SystemContext(locale: 'uz'),
          userContext: UserContext(
            role: AIUserRole.admin,
            preferredLanguage: 'ru',
          ),
          safetyContext: SafetyContext(),
        );

        expect(assembler.assemble(), assembler.assemble());
      },
    );
  });
}

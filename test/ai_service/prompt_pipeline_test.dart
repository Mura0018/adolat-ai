import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/prompt/ai_case_type.dart';
import '../../ai_service/domain/prompt/ai_user_role.dart';
import '../../ai_service/domain/prompt/case_context.dart';
import '../../ai_service/domain/prompt/memory_context.dart';
import '../../ai_service/domain/prompt/prompt_pipeline.dart';
import '../../ai_service/domain/prompt/safety_context.dart';
import '../../ai_service/domain/prompt/system_context.dart';
import '../../ai_service/domain/prompt/user_context.dart';

void main() {
  group('PromptPipeline', () {
    test('composes independent contexts into keyed sections', () {
      final pipeline = const PromptPipeline()
          .withContext(const SystemContext(locale: 'uz'))
          .withContext(
            const UserContext(
              role: AIUserRole.citizen,
              preferredLanguage: 'uz',
            ),
          )
          .withContext(
            const CaseContext(caseType: AICaseType.appeal, appealId: 'a1'),
          );

      final context = pipeline.compose();

      expect(context.sections.keys, {'system', 'user', 'case'});
      expect(context.sectionFor('system'), {
        'locale': 'uz',
        'response_mode': 'default',
      });
      expect(context.sectionFor('user'), {
        'role': 'citizen',
        'preferred_language': 'uz',
      });
      expect(context.sectionFor('case'), {
        'case_type': 'appeal',
        'appeal_id': 'a1',
      });
    });

    test('withContext returns a new pipeline, does not mutate the original', () {
      const base = PromptPipeline();
      final extended = base.withContext(const SystemContext(locale: 'uz'));

      expect(base.contexts, isEmpty);
      expect(extended.contexts, hasLength(1));
    });

    test('a later context with the same key overrides an earlier one', () {
      final pipeline = const PromptPipeline()
          .withContext(const SafetyContext())
          .withContext(const SafetyContext(requiresImpartiality: true));

      final context = pipeline.compose();

      expect(context.sectionFor('safety'), {
        'requires_impartiality': true,
      });
    });

    test('MemoryContext defaults to empty history (foundation placeholder)', () {
      final context = const PromptPipeline()
          .withContext(const MemoryContext())
          .compose();

      expect(context.sectionFor('memory'), {'summarized_history': <String>[]});
    });
  });

  group('CaseContext', () {
    test('asserts caseType matches which id was provided', () {
      // appeal + disputeId -- mismatch.
      expect(
        () => CaseContext(caseType: AICaseType.appeal, disputeId: 'd1'),
        throwsA(isA<AssertionError>()),
      );
      // dispute + appealId -- mismatch.
      expect(
        () => CaseContext(caseType: AICaseType.dispute, appealId: 'a1'),
        throwsA(isA<AssertionError>()),
      );
      // appeal + both ids -- disputeId shouldn't be set at all.
      expect(
        () => CaseContext(
          caseType: AICaseType.appeal,
          appealId: 'a1',
          disputeId: 'd1',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        // Ataylab `const` emas: `const` bo'lsa Dart kompilyatori
        // buzilgan assert'ni derlash vaqtida (const_eval_throws_exception)
        // baholaydi, ish vaqtidagi (runtime) AssertionError sifatida emas
        // — `throwsA` faqat ish vaqtidagi xatolikni ushlay oladi.
        () => CaseContext(caseType: AICaseType.appeal),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts a matching caseType/id pair', () {
      expect(
        () => const CaseContext(caseType: AICaseType.appeal, appealId: 'a1'),
        returnsNormally,
      );
      expect(
        () => const CaseContext(caseType: AICaseType.dispute, disputeId: 'd1'),
        returnsNormally,
      );
    });
  });
}

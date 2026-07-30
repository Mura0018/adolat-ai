import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/workflow/static_information_requirement_catalog.dart';
import '../../ai_service/domain/case/case_category.dart';

void main() {
  const catalog = StaticInformationRequirementCatalog();

  group('StaticInformationRequirementCatalog', () {
    test('every case category has at least one requirement', () {
      for (final category in CaseCategory.values) {
        expect(
          catalog.requirementsFor(category),
          isNotEmpty,
          reason: '${category.name} uchun ma\'lumot bo\'laklari aniqlanmagan',
        );
      }
    });

    test('every case category has at least one mandatory requirement', () {
      for (final category in CaseCategory.values) {
        expect(
          catalog.requirementsFor(category).any((r) => r.isMandatory),
          isTrue,
          reason: '${category.name} uchun birorta ham majburiy bo\'lak yo\'q',
        );
      }
    });

    test('requirement ids are unique across the whole catalog', () {
      final allIds = [
        for (final category in CaseCategory.values)
          ...catalog.requirementsFor(category).map((r) => r.id),
      ];

      expect(allIds.toSet(), hasLength(allIds.length));
    });

    test('is deterministic -- repeated calls return the same list', () {
      for (final category in CaseCategory.values) {
        expect(catalog.requirementsFor(category), catalog.requirementsFor(category));
      }
    });

    test('every requirement carries a non-empty question text', () {
      for (final category in CaseCategory.values) {
        for (final requirement in catalog.requirementsFor(category)) {
          expect(requirement.question.trim(), isNotEmpty);
        }
      }
    });
  });
}

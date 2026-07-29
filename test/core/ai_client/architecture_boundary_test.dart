import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/`ning `ai_service/`ga qarshi tomondagi chegarasi -- Module 4,
/// Phase 4A talabi ("AI Client Interface -- provider-independent
/// client... communicates ONLY with the backend gateway") shu chegara
/// ustiga quriladi: `lib/core/ai_client/` `ai_service/`dagi hech qanday
/// turni to'g'ridan-to'g'ri IMPORT qilmaydi -- faqat bir xil wire
/// shaklga rioya qiluvchi mustaqil ko'chirma (mirror) klasslar bilan
/// ishlaydi (har bir mirror faylining boshidagi izohga qarang).
///
/// `test/ai_service/architecture_boundary_test.dart` chegarani BOSHQA
/// tomondan (`ai_service/` -> Flutter/`lib/`) tekshiradi -- bu test
/// ikkinchi, qarama-qarshi yo'nalishni yopadi.
void main() {
  test('lib/ never imports ai_service/', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'lib/ topilmadi -- bu test repozitoriya ildizidan ishga tushirilishi kerak.',
    );

    final forbidden = RegExp(r'''^\s*import\s+['"](\.\./)*ai_service/''');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
        if (forbidden.hasMatch(lines[lineNumber])) {
          violations.add('${entity.path}:${lineNumber + 1}: ${lines[lineNumber].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'lib/ ai_service/ni hech qachon import qilmasligi shart (backend-first '
          'chegara -- ai_service/README.md, docs/AI_ARCHITECTURE.md). '
          'Topilgan buzilishlar:\n${violations.join('\n')}',
    );
  });
}

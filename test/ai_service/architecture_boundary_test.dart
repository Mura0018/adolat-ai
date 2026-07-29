import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ai_service/` -- Flutter mobil ilova (`lib/`) qismi EMAS va hech
/// qachon Flutter/`lib/`ga bog'liq bo'lmasligi shart
/// (`ai_service/README.md`, "Nega alohida"; `docs/AI_ARCHITECTURE.md`,
/// "Nega lib/dan tashqarida"). Bu qoida ilgari FAQAT kod ko'rib
/// chiqish (code review) intizomi bilan ta'minlangan edi -- bitta
/// umumiy `pubspec.yaml` ostida yotgani uchun `flutter analyze`/
/// `flutter test`ning o'zi `ai_service/` ichida tasodifiy
/// `import 'package:flutter/...'` paydo bo'lishini ushlab qololmas edi
/// (Architecture Review topilmasi -- ilgari HECH QANDAY avtomatik
/// tekshiruv yo'q edi).
///
/// Bu test shu bo'shliqni yopadi: loyihaning yagona sifat darvozasi
/// (`flutter test`) endi bu chegarani ham avtomatik kafolatlaydi --
/// birortasi tasodifan buzilsa, CI shu yerda qizil bo'ladi.
void main() {
  test('ai_service/ never imports Flutter, dart:ui, or lib/ code', () {
    final aiServiceDir = Directory('ai_service');
    expect(
      aiServiceDir.existsSync(),
      isTrue,
      reason:
          'ai_service/ topilmadi -- bu test repozitoriya ildizidan '
          '(pubspec.yaml bilan bir joyda) ishga tushirilishi kerak.',
    );

    // Har biri bitta import qatorini ushlaydigan, maqsadga oid
    // (targeted) naqshlar -- import bo'lmagan joyларда (masalan
    // izohlarda "package:flutter" so'zi tilga olinsa) yolg'on ijobiy
    // bermaslik uchun `import` kalit so'zi bilan boshlanishi talab
    // qilinadi.
    final forbidden = <String, RegExp>{
      'package:flutter': RegExp(r'''^\s*import\s+['"]package:flutter'''),
      'dart:ui': RegExp(r'''^\s*import\s+['"]dart:ui['"]'''),
      'lib/ (Flutter ilovasi kodi)': RegExp(r'''^\s*import\s+['"](\.\./)*lib/'''),
      'package:adolat_ai (asosiy ilova paketi)': RegExp(
        r'''^\s*import\s+['"]package:adolat_ai''',
      ),
    };

    final violations = <String>[];

    for (final entity in aiServiceDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
        final line = lines[lineNumber];
        for (final entry in forbidden.entries) {
          if (entry.value.hasMatch(line)) {
            violations.add(
              '${entity.path}:${lineNumber + 1}: ${entry.key} chegarasi buzildi -- "${line.trim()}"',
            );
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'ai_service/ Flutter/lib bog\'liqligidan mustaqil bo\'lishi shart '
          '(backend-first chegara -- ai_service/README.md, docs/AI_ARCHITECTURE.md, '
          '"Nega lib/dan tashqarida"). Topilgan buzilishlar:\n${violations.join('\n')}',
    );
  });
}

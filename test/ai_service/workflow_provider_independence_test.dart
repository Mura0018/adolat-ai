import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Module 5, Phase 5C talabi: **"No AI provider integration"**,
/// "Recommendation engine abstraction -- provider-independent",
/// "No API keys".
///
/// `test/ai_service/architecture_boundary_test.dart` (Phase 4C)
/// `ai_service/`ning Flutter'dan mustaqilligini avtomatik
/// kafolatlagani kabi, bu test ish oqimi (workflow) qatlamining AI
/// PROVAYDER zanjiridan mustaqilligini kafolatlaydi: agar kimdir
/// kelajakda tavsiya dvigateliga to'g'ridan-to'g'ri provayder
/// adapteri/gateway/protokolni ulasa, CI shu yerda qizil bo'ladi va
/// almashtiriladigan chegara (`RecommendationEngine`) chetlab
/// o'tilmaydi.
void main() {
  const workflowDirectories = ['ai_service/domain/workflow', 'ai_service/data/workflow'];

  test('workflow layer never imports AI providers, gateway, protocol or config', () {
    // Har biri bitta import qatorini ushlaydigan naqshlar -- izohlarda
    // shu nomlar tilga olinsa yolg'on ijobiy bermasligi uchun `import`
    // kalit so'zi talab qilinadi.
    final forbidden = <String, RegExp>{
      'provayder adapterlari (data/providers/)': RegExp(
        r'''^\s*import\s+['"].*data/providers/''',
      ),
      'gateway/ (ijro zanjiri)': RegExp(r'''^\s*import\s+['"].*gateway/'''),
      'protocol/ (simli shartnoma)': RegExp(r'''^\s*import\s+['"].*protocol/'''),
      'config/ (provayder/kalit konfiguratsiyasi)': RegExp(r'''^\s*import\s+['"].*config/'''),
      'AIRepository (provayder chaqiruv zanjiri)': RegExp(
        r'''^\s*import\s+['"].*repositories/ai_repository\.dart''',
      ),
      'AIProviderId': RegExp(r'''^\s*import\s+['"].*ai_provider_id\.dart'''),
    };

    final violations = <String>[];

    for (final path in workflowDirectories) {
      final directory = Directory(path);
      expect(
        directory.existsSync(),
        isTrue,
        reason: '$path topilmadi -- test repozitoriya ildizidan ishga tushirilishi kerak.',
      );

      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
          for (final entry in forbidden.entries) {
            if (entry.value.hasMatch(lines[lineNumber])) {
              violations.add(
                '${entity.path}:${lineNumber + 1}: ${entry.key} -- "${lines[lineNumber].trim()}"',
              );
            }
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Ish oqimi qatlami AI provayder zanjiridan mustaqil bo\'lishi shart '
          '(docs/AI_ARCHITECTURE.md, "AI Assistance Workflow Foundation (Module 5, Phase 5C)"). '
          'Topilgan buzilishlar:\n${violations.join('\n')}',
    );
  });

  test('workflow layer contains no credential or API key handling', () {
    final forbidden = RegExp(r'apiKey|api_key|secret|Bearer|credential', caseSensitive: false);
    // IZOH qatorlari tekshirilmaydi: hujjat izohida boshqa qatlamga
    // ("`AIBackendCredential` bilan bir xil intizom") HAVOLA berish --
    // KODda hisob ma'lumoti bilan ishlash emas. Tekshiruvning maqsadi
    // -- ijro etiladigan kod, `architecture_boundary_test.dart`ning
    // `import` kalit so'ziga bog'lanishi bilan bir xil sabab.
    final commentLine = RegExp(r'^\s*(///|//|\*|/\*)');
    final violations = <String>[];

    for (final path in workflowDirectories) {
      for (final entity in Directory(path).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
          if (commentLine.hasMatch(lines[lineNumber])) continue;
          if (forbidden.hasMatch(lines[lineNumber])) {
            violations.add('${entity.path}:${lineNumber + 1}: ${lines[lineNumber].trim()}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Talab: "No API keys" -- ish oqimi qatlami hech qanday hisob ma\'lumoti bilan '
          'ishlamaydi.\n${violations.join('\n')}',
    );
  });
}

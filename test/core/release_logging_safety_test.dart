import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `docs/DEVELOPMENT_RULES.md`, **11-band**: "Release build'da debug
/// loglar ishlamasligi shart."
///
/// Bu qoida ilgari FAQAT kod ko'rib chiqish intizomiga tayanardi va
/// aynan shu sababli buzilgan holda 4 kun qolib ketdi
/// (`lib/services/network/dio_client.dart`ning `LogInterceptor`i --
/// `PROJECT_AUDIT.md` 2026-07-26 va 2026-07-30 auditlarining #1
/// xavfsizlik topilmasi). Bu test shu bo'shliqni yopadi: endi qoidani
/// `flutter test`ning o'zi (ya'ni CI) majburlaydi.
///
/// **Nega xatti-harakat (behaviour) testi emas, manba skaneri:**
/// `flutter test` har doim DEBUG rejimida ishlaydi (`kDebugMode == true`),
/// shuning uchun "release build'da nima bo'ladi"ni ish vaqtida tekshirib
/// BO'LMAYDI -- release xatti-harakati faqat kompilyatsiya vaqtida
/// (tree-shaking) yuzaga keladi. Yagona ishonchli avtomatik kafolat --
/// manba matnining o'zini tekshirish, xuddi
/// `test/ai_service/architecture_boundary_test.dart` va
/// `test/ai_service/workflow_provider_independence_test.dart` qilgani
/// kabi.
///
/// **Cheklov (ataylab va ochiq):** tekshiruv FAYL darajasida ishlaydi --
/// loglash chaqiruvi bor faylda `kDebugMode` ham borligini talab
/// qiladi, lekin aynan SHU chaqiruv shu guard ICHIDA ekanligini
/// isbotlamaydi (buning uchun to'liq AST tahlili kerak bo'lardi).
/// Amaliy qiymati baribir yuqori: guardni butunlay unutish -- eng
/// ehtimolli xato -- endi CI'da ushlanadi.
void main() {
  /// Loglash chaqirig'i bo'lgan faylda `kDebugMode` guard'i ham
  /// bo'lishi shart.
  const guardedLoggingCalls = <String, String>{
    'LogInterceptor': 'Dio so\'rov/javob loglash interceptori',
    'debugPrint(': 'Flutter konsol logi',
    'developer.log(': 'dart:developer logi',
  };

  final commentLine = RegExp(r'^\s*(///|//|\*|/\*)');

  List<File> libDartFiles() {
    return Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.freezed.dart'))
        .toList();
  }

  test('lib/ contains no unguarded debug logging (DEVELOPMENT_RULES 11-band)', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'lib/ topilmadi -- bu test repozitoriya ildizidan ishga tushirilishi kerak.',
    );

    final violations = <String>[];

    for (final file in libDartFiles()) {
      final lines = file.readAsLinesSync();
      final codeLines = [
        for (final line in lines)
          if (!commentLine.hasMatch(line)) line,
      ];
      final code = codeLines.join('\n');

      for (final entry in guardedLoggingCalls.entries) {
        if (!code.contains(entry.key)) continue;

        if (!code.contains('kDebugMode')) {
          final lineNumber = lines.indexWhere(
            (l) => l.contains(entry.key) && !commentLine.hasMatch(l),
          );
          violations.add(
            '${file.path}:${lineNumber + 1}: ${entry.value} (`${entry.key}`) '
            'ishlatilgan, lekin faylda `kDebugMode` guard\'i yo\'q',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Release build\'da debug loglar ishlamasligi shart '
          '(docs/DEVELOPMENT_RULES.md, 11-band). Har bir loglash chaqirig\'i '
          '`if (kDebugMode) { ... }` ichida bo\'lishi kerak.\n'
          'Topilgan buzilishlar:\n${violations.join('\n')}',
    );
  });

  test('lib/ never uses raw print() -- it cannot be stripped from release builds', () {
    // `analysis_options.yaml`dagi `avoid_print: true` buni allaqachon
    // ushlaydi, lekin lint sozlamasi kelajakda yumshatilishi mumkin --
    // bu test esa qoidani sifat darvozasining o'ziga bog'laydi.
    final printCall = RegExp(r'(^|[^.\w])print\s*\(');
    final violations = <String>[];

    for (final file in libDartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (commentLine.hasMatch(lines[i])) continue;
        if (printCall.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty, reason: 'Xom `print()` topildi:\n${violations.join('\n')}');
  });

  test('the Dio client specifically guards its LogInterceptor', () {
    // Aniq, nomlangan regressiya testi -- yuqoridagi umumiy skaner
    // kelajakda o'zgarsa ham, AYNAN shu topilma (auditning #1 bandi)
    // qaytib kelmasligini kafolatlaydi.
    final source = File('lib/services/network/dio_client.dart').readAsStringSync();

    expect(source.contains('LogInterceptor'), isTrue, reason: 'Test eskirgan -- fayl o\'zgargan.');
    expect(
      source.contains('if (kDebugMode)'),
      isTrue,
      reason:
          'dio_client.dart `LogInterceptor`ni `if (kDebugMode)` bilan o\'rashi shart '
          '(PROJECT_AUDIT.md, #1 xavfsizlik topilmasi; ROADMAP.md, Phase 1 Deliverables).',
    );

    // Guard interceptor qo'shilishidan OLDIN kelishi kerak.
    expect(
      source.indexOf('if (kDebugMode)') < source.indexOf('dio.interceptors.add'),
      isTrue,
      reason: '`kDebugMode` guard\'i `dio.interceptors.add(...)` dan oldin turishi kerak.',
    );
  });
}

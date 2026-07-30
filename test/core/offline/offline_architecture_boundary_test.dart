import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Module 6A qoidalari: **AI provider ulanmaydi, API kalit
/// qo'shilmaydi, HTTP/WebSocket yozilmaydi, backend/Edge Function
/// yozilmaydi, UI o'zgartirilmaydi, yangi Flutter bog'liqligi
/// qo'shilmaydi.**
///
/// Bu test shu qoidalarni CI'ga bog'laydi —
/// `test/ai_service/architecture_boundary_test.dart` (Module 4C),
/// `workflow_provider_independence_test.dart` (5C) va
/// `release_logging_safety_test.dart` bilan bir xil yondashuv:
/// arxitektura chegarasi kod ko'rib chiqish intizomiga emas,
/// `flutter test`ning o'ziga tayanadi.
void main() {
  const offlineDir = 'lib/core/offline';
  final commentLine = RegExp(r'^\s*(///|//|\*|/\*)');

  List<File> offlineFiles() {
    return Directory(offlineDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  setUp(() {
    expect(
      Directory(offlineDir).existsSync(),
      isTrue,
      reason: '$offlineDir topilmadi -- test repozitoriya ildizidan ishga tushirilishi kerak.',
    );
  });

  test('offline layer performs no network I/O and depends on no backend SDK', () {
    // Har biri bitta import qatorini ushlaydi; izohlarda shu nomlar
    // tilga olinsa yolg'on ijobiy bermasligi uchun `import` talab
    // qilinadi.
    final forbiddenImports = <String, RegExp>{
      'HTTP klienti (dio)': RegExp(r'''^\s*import\s+['"]package:dio'''),
      'HTTP klienti (http)': RegExp(r'''^\s*import\s+['"]package:http'''),
      'WebSocket (dart:io/web_socket)': RegExp(r'''^\s*import\s+['"].*web_socket'''),
      'Supabase SDK': RegExp(r'''^\s*import\s+['"]package:supabase'''),
      'Supabase Flutter SDK': RegExp(r'''^\s*import\s+['"]package:supabase_flutter'''),
      'Flutter UI (material/widgets)': RegExp(
        r'''^\s*import\s+['"]package:flutter/(material|widgets|cupertino)''',
      ),
      'Riverpod (holat/DI — UI qatlami)': RegExp(r'''^\s*import\s+['"]package:flutter_riverpod'''),
      'AI service (backend kodi)': RegExp(r'''^\s*import\s+['"].*ai_service/'''),
      'AI klienti': RegExp(r'''^\s*import\s+['"].*ai_client/'''),
      'dart:io (fayl/soket)': RegExp(r'''^\s*import\s+['"]dart:io['"]'''),
    };

    final violations = <String>[];

    for (final file in offlineFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in forbiddenImports.entries) {
          if (entry.value.hasMatch(lines[i])) {
            violations.add('${file.path}:${i + 1}: ${entry.key} -- "${lines[i].trim()}"');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Module 6A faqat arxitektura va interfeyslardan iborat: HTTP/WebSocket, backend SDK, '
          'AI provayder va UI bog\'liqliklari taqiqlangan. Haqiqiy tarmoq ishi kelgusida '
          '`SyncOperationHandler` implementatsiyasida bo\'ladi.\n${violations.join('\n')}',
    );
  });

  test('offline layer never handles credentials or API keys', () {
    // docs/ARCHITECTURE.md, "Local Storage": tokenlar Local Storage'da
    // EMAS, faqat Flutter Secure Storage'da saqlanadi.
    final forbidden = RegExp(r'apiKey|api_key|accessToken|refreshToken|Bearer', caseSensitive: false);
    final violations = <String>[];

    for (final file in offlineFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (commentLine.hasMatch(lines[i])) continue;
        if (forbidden.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Autentifikatsiya tokenlari mahalliy saqlash qatlamiga tushmasligi shart '
          '(docs/ARCHITECTURE.md, "Local Storage" -> maxfiy ma\'lumotlar bilan chegara; '
          'docs/SECURITY.md, "JWT Security").\n${violations.join('\n')}',
    );
  });

  test('offline layer does not import feature code -- it stays provider-independent', () {
    // core/ hech qachon features/ga bog'lanmasligi kerak
    // (docs/ARCHITECTURE.md, "Ichki Kod Arxitekturasi" -- bog'liqlik
    // yo'nalishi). Aks holda umumiy offline yadro bitta feature
    // shakliga qulflanib qolardi.
    final featureImport = RegExp(r'''^\s*import\s+['"].*features/''');
    final violations = <String>[];

    for (final file in offlineFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (featureImport.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('Module 6A adds no new package dependency', () {
    // Qoida: "Flutter dependency qo'shma". Offline qatlami faqat Dart
    // yadrosi (dart:async) va loyihaning o'z kodidan foydalanadi.
    final packageImport = RegExp(r'''^\s*import\s+['"]package:([a-z_0-9]+)/''');
    final allowedPackages = <String>{'adolat_ai'};
    final violations = <String>[];

    for (final file in offlineFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = packageImport.firstMatch(lines[i]);
        if (match == null) continue;
        final package = match.group(1)!;
        if (!allowedPackages.contains(package)) {
          violations.add('${file.path}:${i + 1}: package:$package');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Module 6A yangi paket bog\'liqligi qo\'shmaydi -- saqlash paketi tanlovi '
          'alohida qaror (ADR) sifatida rasmiylashtirilishi kerak.\n${violations.join('\n')}',
    );
  });
}

import 'package:adolat_ai/features/appeals/domain/entities/appeal_status.dart';
import 'package:adolat_ai/features/appeals/presentation/widgets/appeal_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loyihadagi BIRINCHI widget testi -- `test/features/` uchun widget
/// test infratuzilmasini o'rnatadi (2026-07-30 auditi, 2-topilma:
/// "Widget/integration test umuman yo'q").
///
/// `AppealStatusBadge` ataylab tanlandi: u `docs/UI.md`ning "Holatni
/// shaffof ko'rsatish" tamoyilini bevosita amalga oshiradi -- ya'ni
/// foydalanuvchi murojaati qaysi bosqichda ekanini AYNAN shu widget
/// aytadi. Belgi noto'g'ri/bo'sh bo'lsa, foydalanuvchi keyingi qadamni
/// bilmay qoladi (`DEVELOPMENT_RULES.md`, 19-band).
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('AppealStatusBadge', () {
    testWidgets('renders a non-empty Uzbek label for every status', (tester) async {
      // Yangi `AppealStatus` qiymati qo'shilib, belgi yangilanmasa --
      // shu test qizil bo'ladi (switch to'liqligi kompilyatsiyada, matn
      // esa shu yerda kafolatlanadi).
      for (final status in AppealStatus.values) {
        await tester.pumpWidget(_wrap(AppealStatusBadge(status: status)));

        final text = tester.widget<Text>(find.byType(Text));
        expect(
          text.data?.trim(),
          isNotEmpty,
          reason: '${status.name} uchun matn bo\'sh bo\'lmasligi kerak',
        );
      }
    });

    testWidgets('shows distinct labels for draft and submitted', (tester) async {
      await tester.pumpWidget(_wrap(const AppealStatusBadge(status: AppealStatus.draft)));
      expect(find.text('Qoralama'), findsOneWidget);

      await tester.pumpWidget(_wrap(const AppealStatusBadge(status: AppealStatus.submitted)));
      expect(find.text('Yuborildi'), findsOneWidget);
      expect(find.text('Qoralama'), findsNothing);
    });

    testWidgets('gives every status its own label -- no two statuses look alike', (
      tester,
    ) async {
      final labels = <String>{};

      for (final status in AppealStatus.values) {
        await tester.pumpWidget(_wrap(AppealStatusBadge(status: status)));
        labels.add(tester.widget<Text>(find.byType(Text)).data!);
      }

      expect(
        labels,
        hasLength(AppealStatus.values.length),
        reason: 'Ikki xil holat bir xil matn ko\'rsatmasligi kerak',
      );
    });

    testWidgets('renders without overflow in a narrow layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const AppealStatusBadge(status: AppealStatus.inReview)));

      expect(tester.takeException(), isNull);
    });
  });
}

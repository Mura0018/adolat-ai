import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Ilovaning ildiz widgeti.
///
/// Bu yerda hech qanday biznes logika yo'q — faqat `MaterialApp.router`ni
/// tema va marshrutlash providerlariga ulash.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Adolat AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      // `flutter gen-l10n` ishga tushgach, `AppLocalizations.delegate`
      // shu ro'yxatga qo'shiladi (docs/setup.md ga qarang).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uz'), Locale('en')],
    );
  }
}

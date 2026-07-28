import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Ilova ochilganda ko'rsatiladigan boshlang'ich ekran (docs/UI.md, "App
/// Entry Flow", 1-qadam). O'zi hech qanday yo'naltirish qilmaydi — bu
/// `router/app_router.dart`dagi `redirect` mantig'ining mas'uliyati;
/// bu ekran faqat `authStateChangesProvider` hali birinchi qiymatini
/// bermagan payt (`AsyncLoading`) ko'rinadi.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sessiya holatini kuzatish shu yerda boshlanadi — provider
    // `authRepositoryProvider.authStateChanges`ga ulanadi va router bu
    // qiymatni `redirect`da o'qiydi.
    ref.watch(authStateChangesProvider);

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

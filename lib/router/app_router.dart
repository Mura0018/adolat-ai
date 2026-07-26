import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';

/// Ilovaning yagona `GoRouter` konfiguratsiyasi.
///
/// `home` marshruti hozircha placeholder ekranga ishora qiladi — birinchi
/// haqiqiy feature qo'shilganda bu yerga uning `presentation/screens/`
/// ekrani ulanadi.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const _PlaceholderHomeScreen(),
      ),
    ],
  );
});

class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Adolat AI')),
    );
  }
}

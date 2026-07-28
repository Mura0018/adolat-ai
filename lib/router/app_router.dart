import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appeals/presentation/screens/appeal_create_screen.dart';
import '../features/appeals/presentation/screens/appeal_detail_screen.dart';
import '../features/appeals/presentation/screens/appeals_list_screen.dart';
import '../features/disputes/presentation/screens/dispute_create_screen.dart';
import '../features/disputes/presentation/screens/dispute_detail_screen.dart';
import '../features/disputes/presentation/screens/disputes_list_screen.dart';
import 'route_paths.dart';

/// Ilovaning yagona `GoRouter` konfiguratsiyasi.
///
/// `home` marshruti hozircha placeholder ekranga ishora qiladi — auth
/// oqimi (kirish/ro'yxatdan o'tish) alohida feature sifatida hali
/// qo'shilmagan (Case Management Foundation ko'lamidan tashqarida);
/// murojaat/nizo marshrutlari esa quyida to'liq ulangan.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const _PlaceholderHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.appeals,
        builder: (context, state) => const AppealsListScreen(),
      ),
      GoRoute(
        path: RoutePaths.appealCreate,
        builder: (context, state) => const AppealCreateScreen(),
      ),
      GoRoute(
        path: RoutePaths.appealDetail,
        builder: (context, state) => AppealDetailScreen(
          appealId: state.pathParameters['appealId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.disputes,
        builder: (context, state) => const DisputesListScreen(),
      ),
      GoRoute(
        path: RoutePaths.disputeCreate,
        builder: (context, state) => const DisputeCreateScreen(),
      ),
      GoRoute(
        path: RoutePaths.disputeDetail,
        builder: (context, state) => DisputeDetailScreen(
          disputeId: state.pathParameters['disputeId']!,
        ),
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

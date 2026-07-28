import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appeals/presentation/screens/appeal_create_screen.dart';
import '../features/appeals/presentation/screens/appeal_detail_screen.dart';
import '../features/appeals/presentation/screens/appeals_list_screen.dart';
import '../features/auth/domain/entities/user_role.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/citizen_register_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/organization_register_screen.dart';
import '../features/auth/presentation/screens/password_reset_confirm_screen.dart';
import '../features/auth/presentation/screens/password_reset_request_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/role_select_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';
import '../features/disputes/presentation/screens/dispute_create_screen.dart';
import '../features/disputes/presentation/screens/dispute_detail_screen.dart';
import '../features/disputes/presentation/screens/disputes_list_screen.dart';
import 'go_router_refresh_notifier.dart';
import 'route_paths.dart';

/// Ilovaning yagona `GoRouter` konfiguratsiyasi.
///
/// **Auth guard (docs/UI.md, "Autentifikatsiya to'sig'i"):** `redirect`
/// `authStateChangesProvider`ning joriy qiymatini `ref.read` orqali
/// sinxron o'qiydi; `refreshListenable` (`GoRouterRefreshNotifier`) shu
/// providerning tagidagi oqim yangi qiymat chiqarganda (kirish, chiqish,
/// sessiya tiklanishi) `redirect`ni qayta ishga tushiradi — bu orqan
/// hech bir ekran o'zi qo'lda navigatsiya qilishi shart emas, faqat
/// auth amalini bajaradi, qolganini guard hal qiladi.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(
    ref.watch(authRepositoryProvider).authStateChanges,
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final location = state.matchedLocation;
      final isSplash = location == RoutePaths.splash;
      final isAuthRoute = location.startsWith('/auth');

      // Sessiya hali tekshirilmoqda (docs/UI.md, "App Entry Flow",
      // 1-qadam) — splash'da qoladi.
      if (authAsync.isLoading) {
        return isSplash ? null : RoutePaths.splash;
      }

      final user = authAsync.valueOrNull;

      if (user == null) {
        return isAuthRoute ? null : RoutePaths.authLogin;
      }

      // Sessiya mavjud — auth/splash ekranlariga qaytarilmaydi
      // (docs/UI.md, "Autentifikatsiya to'sig'i").
      if (isSplash || isAuthRoute) {
        return user.role == UserRole.admin
            ? RoutePaths.adminAppeals
            : RoutePaths.home;
      }

      // Rolga mos bo'lmagan shoxobchaga kirishning oldini olish
      // (docs/UI.md, "User Roles": "Admin oddiy foydalanuvchi ekranlarini
      // ko'rmaydi").
      final isAdminRoute = location.startsWith('/admin');
      if (user.role == UserRole.admin && !isAdminRoute) {
        return RoutePaths.adminAppeals;
      }
      if (user.role != UserRole.admin && isAdminRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.authRoleSelect,
        builder: (context, state) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: RoutePaths.authRegisterCitizen,
        builder: (context, state) => const CitizenRegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.authRegisterOrganization,
        builder: (context, state) => const OrganizationRegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.authVerifyOtp,
        // `extra` orqali kelgan telefon raqami yo'q bo'lsa (masalan
        // to'g'ridan-to'g'ri havola/eski bookmark orqali, ayniqsa Flutter
        // Web'da) — bu ekran hech narsani tasdiqlay olmaydi, xavfsiz
        // holatga qaytariladi (`DEVELOPMENT_RULES.md`, "No Dead End
        // Rule" — qulab tushish o'rniga tushunarli qayta yo'naltirish).
        redirect: (context, state) =>
            state.extra is String ? null : RoutePaths.authRegisterCitizen,
        builder: (context, state) =>
            VerifyOtpScreen(phoneNumber: state.extra! as String),
      ),
      GoRoute(
        path: RoutePaths.authLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.authResetPasswordRequest,
        builder: (context, state) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: RoutePaths.authResetPasswordConfirm,
        redirect: (context, state) => state.extra is String
            ? null
            : RoutePaths.authResetPasswordRequest,
        builder: (context, state) =>
            PasswordResetConfirmScreen(identifier: state.extra! as String),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _CitizenOrgShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const _HomePlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
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
            ],
          ),
          StatefulShellBranch(
            routes: [
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
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.notifications,
                builder: (context, state) =>
                    const _NotificationsPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminAppeals,
                builder: (context, state) => const _AdminPlaceholderScreen(
                  title: 'Murojaatlar boshqaruvi',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminDisputes,
                builder: (context, state) => const _AdminPlaceholderScreen(
                  title: 'Nizolar boshqaruvi',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminReference,
                builder: (context, state) => const _AdminPlaceholderScreen(
                  title: 'Ma\'lumotnomalar',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminAuditLog,
                builder: (context, state) => const _AdminPlaceholderScreen(
                  title: 'Audit jurnali',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Fuqaro/Tashkilot uchun umumiy pastki navigatsiya (docs/UI.md,
/// "Navigation Structure": "Ikkala rol ham bir xil navigatsiya
/// tuzilmasidan foydalanadi").
class _CitizenOrgShell extends StatelessWidget {
  const _CitizenOrgShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Bosh sahifa',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Murojaatlarim',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Nizolarim',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Xabarnomalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Admin uchun alohida, boshqaruv (dashboard) yo'naltirilgan navigatsiya
/// (docs/UI.md, "Navigation Structure": "Admin uchun — butunlay alohida").
class _AdminShell extends StatelessWidget {
  const _AdminShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Murojaatlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Nizolar',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Ma\'lumotnomalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Audit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// "Bosh sahifa" — hozircha bo'sh, faqat navigatsiya skeleti (ROADMAP.md,
/// "Phase 1 Deliverables": "bo'sh (placeholder), lekin navigatsiya
/// jihatidan to'liq ishlaydigan"). Haqiqiy tarkib (statistika, so'nggi
/// murojaat/nizolar) kelgusi bosqichda qo'shiladi.
class _HomePlaceholderScreen extends StatelessWidget {
  const _HomePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adolat AI')),
      body: const Center(child: Text('Bosh sahifa (tez orada)')),
    );
  }
}

/// "Xabarnomalar" — hozircha bo'sh, faqat navigatsiya skeleti (`docs/
/// DATABASE.md`, 12-jadval `notifications`; feature Bosqich 5'da
/// to'liq ishga tushiriladi).
class _NotificationsPlaceholderScreen extends StatelessWidget {
  const _NotificationsPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xabarnomalar')),
      body: const Center(child: Text('Xabarnomalar (tez orada)')),
    );
  }
}

/// Admin bo'limlari uchun umumiy placeholder — Bosqich 5'da haqiqiy
/// boshqaruv interfeysiga almashtiriladi (docs/UI.md, "User Roles":
/// Admin bo'limi tavsifi).
class _AdminPlaceholderScreen extends StatelessWidget {
  const _AdminPlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title (tez orada)')),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Har qanday `Stream`ni `GoRouter`ning `refreshListenable`iga moslashtiradi
/// — oqim yangi qiymat chiqarganda `redirect` qayta baholanishi uchun.
///
/// `authStateChangesProvider` (Riverpod `StreamProvider`) o'zi
/// `Listenable` emas, shuning uchun bu ko'prik kerak (docs/UI.md,
/// "Autentifikatsiya to'sig'i (auth guard)").
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_presentation.dart';
import '../providers/auth_providers.dart';

/// Chiqish tasdiqlash dialogi (docs/UI.md, "Authentication Screens" —
/// "Chiqish (logout) tasdiqlashi: tasodifiy bosishning oldini olish
/// uchun qisqa tasdiqlash so'raladi").
///
/// Muvaffaqiyatli chiqishdan keyin bu widget o'zi hech qayerga
/// yo'naltirmaydi — `router/app_router.dart`dagi reaktiv `redirect`
/// `authStateChangesProvider` orqali avtomatik ishlaydi.
Future<void> showLogoutConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chiqish'),
      content: const Text('Hisobingizdan chiqishni xohlaysizmi?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Chiqish'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final success = await ref.read(authControllerProvider.notifier).logout();

  if (!context.mounted || success) return;

  final state = ref.read(authControllerProvider);
  state.whenOrNull(
    error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describeErrorForUser(error))),
    ),
  );
}

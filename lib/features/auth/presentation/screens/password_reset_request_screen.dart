import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../providers/auth_providers.dart';

/// Parolni tiklash oqimining birinchi qadami (docs/UI.md, "Authentication
/// Screens" — "Parolni tiklash oqimi": telefon/email orqali so'rov
/// yuborish).
class PasswordResetRequestScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState
    extends ConsumerState<PasswordResetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(identifier: identifier);

    if (!mounted) return;

    if (success) {
      context.pushReplacement(
        RoutePaths.authResetPasswordConfirm,
        extra: identifier,
      );
    } else {
      final state = ref.read(authControllerProvider);
      state.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeErrorForUser(error))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authControllerProvider);
    final isSubmitting = formState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Parolni tiklash')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Ro\'yxatdan o\'tishda ishlatilgan telefon raqami yoki '
              'emailingizni kiriting — tasdiqlash kodi yuboriladi.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Telefon raqami yoki email',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Telefon raqami yoki email kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kodni yuborish'),
            ),
          ],
        ),
      ),
    );
  }
}

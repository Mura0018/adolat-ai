import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_presentation.dart';
import '../providers/auth_providers.dart';

/// Parolni tiklash oqimining ikkinchi qadami (docs/UI.md, "Authentication
/// Screens" — "tasdiqlash kodi/havola orqali yangi parol o'rnatadi").
///
/// Muvaffaqiyatli bo'lsa, Supabase tomonidan sessiya o'rnatiladi va
/// `router/app_router.dart`dagi reaktiv `redirect` foydalanuvchini
/// avtomatik asosiy ekranga yo'naltiradi.
class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  const PasswordResetConfirmScreen({required this.identifier, super.key});

  final String identifier;

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState
    extends ConsumerState<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .confirmPasswordReset(
          identifier: widget.identifier,
          otpCode: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted || success) return;

    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeErrorForUser(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authControllerProvider);
    final isSubmitting = formState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi parol o\'rnatish')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${widget.identifier}ga yuborilgan tasdiqlash kodini kiriting.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Tasdiqlash kodi'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Kod kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Yangi parol'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 6)
                  ? 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak'
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
                  : const Text('Parolni o\'rnatish'),
            ),
          ],
        ),
      ),
    );
  }
}

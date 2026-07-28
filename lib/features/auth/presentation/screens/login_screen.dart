import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../providers/auth_providers.dart';

/// Kirish (login) ekrani (docs/UI.md, "Authentication Screens" —
/// "Kirish (login) ekrani": telefon/email va parol, parolni tiklash
/// havolasi bilan).
///
/// Muvaffaqiyatli kirishdan keyin bu ekran o'zi hech qayerga
/// yo'naltirmaydi — `router/app_router.dart`dagi reaktiv `redirect`
/// mantig'i `authStateChangesProvider` orqali avtomatik ishlaydi.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
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
      appBar: AppBar(title: const Text('Kirish')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Telefon raqami yoki email',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Telefon raqami yoki email kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Parol'),
              obscureText: true,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Parol kiritilishi shart'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    context.push(RoutePaths.authResetPasswordRequest),
                child: const Text('Parolni unutdingizmi?'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isSubmitting ? null : _login,
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirish'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(RoutePaths.authRoleSelect),
              child: const Text('Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting'),
            ),
          ],
        ),
      ),
    );
  }
}

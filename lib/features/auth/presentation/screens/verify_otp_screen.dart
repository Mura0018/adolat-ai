import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_presentation.dart';
import '../providers/auth_providers.dart';

/// Telefon tasdiqlash (SMS) ekrani (docs/UI.md, "Authentication Screens"
/// — "Telefon tasdiqlash (SMS) ekrani": kod kiritish, qayta yuborish).
///
/// Muvaffaqiyatli tasdiqlashdan keyin bu ekran o'zi hech qayerga
/// yo'naltirmaydi — `verifyPhoneOtp` sessiya o'rnatadi, bu esa
/// `authStateChangesProvider` orqali `router/app_router.dart`dagi
/// `redirect` mantig'ini avtomatik ishga tushiradi (reaktiv oqim).
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneOtp(
          phoneNumber: widget.phoneNumber,
          otpCode: _codeController.text.trim(),
        );

    if (!mounted || success) return;

    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeErrorForUser(error))),
      ),
    );
  }

  Future<void> _resend() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendPhoneOtp(phoneNumber: widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kod qayta yuborildi')));
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
      appBar: AppBar(title: const Text('Telefonni tasdiqlash')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.phoneNumber} raqamiga yuborilgan tasdiqlash kodini '
              'kiriting.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Tasdiqlash kodi'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Kod kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting ? null : _verify,
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tasdiqlash'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isSubmitting ? null : _resend,
              child: const Text('Kodni qayta yuborish'),
            ),
          ],
        ),
      ),
    );
  }
}

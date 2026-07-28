import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../providers/auth_providers.dart';

/// Tashkilot ro'yxatdan o'tish shakli (docs/UI.md, "Authentication
/// Screens" — "Tashkilot ro'yxatdan o'tish shakli"; docs/DATABASE.md,
/// 2-jadval).
class OrganizationRegisterScreen extends ConsumerStatefulWidget {
  const OrganizationRegisterScreen({super.key});

  @override
  ConsumerState<OrganizationRegisterScreen> createState() =>
      _OrganizationRegisterScreenState();
}

class _OrganizationRegisterScreenState
    extends ConsumerState<OrganizationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _contactEmailController = TextEditingController();

  bool _usePhone = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _legalAddressController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final success = await ref
        .read(authControllerProvider.notifier)
        .registerOrganization(
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          legalName: _legalNameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          legalAddress: _legalAddressController.text.trim(),
          phoneNumber: _usePhone ? identifier : null,
          email: _usePhone ? null : identifier,
          contactEmail: _contactEmailController.text.trim().isEmpty
              ? null
              : _contactEmailController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      if (_usePhone) {
        context.pushReplacement(
          RoutePaths.authVerifyOtp,
          extra: identifier,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ro\'yxatdan o\'tish so\'rovi qabul qilindi. Emailingizni tekshiring.',
            ),
          ),
        );
        context.pushReplacement(RoutePaths.authLogin);
      }
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
      appBar: AppBar(
        title: const Text('Tashkilot sifatida ro\'yxatdan o\'tish'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Vakil to\'liq ismi',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vakil ismi kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Telefon')),
                ButtonSegment(value: false, label: Text('Email')),
              ],
              selected: {_usePhone},
              onSelectionChanged: (selection) =>
                  setState(() => _usePhone = selection.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: _usePhone
                    ? 'Telefon raqami (+998...)'
                    : 'Email',
              ),
              keyboardType: _usePhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? (_usePhone
                        ? 'Telefon raqami kiritilishi shart'
                        : 'Email kiritilishi shart')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Parol'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 6)
                  ? 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak'
                  : null,
            ),
            const Divider(height: 32),
            Text(
              'Tashkilot ma\'lumotlari',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _legalNameController,
              decoration: const InputDecoration(
                labelText: 'Tashkilotning rasmiy nomi',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Tashkilot nomi kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(labelText: 'STIR/INN'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'STIR kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _legalAddressController,
              decoration: const InputDecoration(labelText: 'Yuridik manzil'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Yuridik manzil kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'Rasmiy aloqa email (ixtiyoriy)',
              ),
              keyboardType: TextInputType.emailAddress,
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
                  : const Text('Ro\'yxatdan o\'tish'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../../../legal_reference/presentation/providers/legal_reference_providers.dart';
import '../providers/disputes_providers.dart';

/// Yangi nizo yaratish shakli (docs/UI.md, "Authentication Screens"dan
/// keyingi asosiy oqim; docs/ARCHITECTURE.md, "Case Lifecycle" bo'limi).
///
/// MVP ko'lami: faqat ro'yxatdan o'tmagan qarshi tomon (`respondentType
/// = 'unregistered'`) bilan nizo yaratish qo'llab-quvvatlanadi.
class DisputeCreateScreen extends ConsumerStatefulWidget {
  const DisputeCreateScreen({super.key});

  @override
  ConsumerState<DisputeCreateScreen> createState() =>
      _DisputeCreateScreenState();
}

class _DisputeCreateScreenState extends ConsumerState<DisputeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _respondentNameController = TextEditingController();

  String? _categoryId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _respondentNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategoriyani tanlang')));
      return;
    }

    await ref
        .read(disputeFormControllerProvider.notifier)
        .create(
          categoryId: _categoryId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          respondentDisplayName: _respondentNameController.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(disputeFormControllerProvider);
    state.whenOrNull(
      data: (dispute) {
        if (dispute != null) {
          ref.invalidate(myDisputesProvider);
          context.pushReplacement(RoutePaths.disputeDetailFor(dispute.id));
        }
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeErrorForUser(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeLegalCategoriesProvider);
    final formState = ref.watch(disputeFormControllerProvider);
    final isSubmitting = formState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi nizo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) =>
                  const Text('Kategoriyalarni yuklab bo\'lmadi'),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Huquqiy yo\'nalish',
                ),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nameUz),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Nizo sarlavhasi'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Sarlavha kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _respondentNameController,
              decoration: const InputDecoration(
                labelText: 'Qarshi tomon ismi/nomi',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Qarshi tomon nomi kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Nizo mazmuni (sizning faktlaringiz)',
              ),
              maxLines: 8,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Nizo mazmuni kiritilishi shart'
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
                  : const Text('Nizoni ochish'),
            ),
          ],
        ),
      ),
    );
  }
}

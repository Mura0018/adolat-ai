import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../../../legal_reference/presentation/providers/legal_reference_providers.dart';
import '../providers/appeals_providers.dart';

/// Yangi murojaat qoralamasini yaratish shakli (docs/UI.md,
/// "Authentication Screens"dan keyingi asosiy oqim; docs/ARCHITECTURE.md,
/// "Case Lifecycle" bo'limi: `draft` holati).
class AppealCreateScreen extends ConsumerStatefulWidget {
  const AppealCreateScreen({super.key});

  @override
  ConsumerState<AppealCreateScreen> createState() =>
      _AppealCreateScreenState();
}

class _AppealCreateScreenState extends ConsumerState<AppealCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _categoryId;
  String? _recipientBodyId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _recipientBodyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategoriya va davlat organini tanlang'),
        ),
      );
      return;
    }

    await ref
        .read(appealFormControllerProvider.notifier)
        .createDraft(
          categoryId: _categoryId!,
          recipientBodyId: _recipientBodyId!,
          title: _titleController.text.trim(),
          bodyText: _bodyController.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(appealFormControllerProvider);
    state.whenOrNull(
      data: (appeal) {
        if (appeal != null) {
          ref.invalidate(myAppealsProvider);
          context.pushReplacement(RoutePaths.appealDetailFor(appeal.id));
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
    final bodiesAsync = ref.watch(activeGovernmentBodiesProvider);
    final formState = ref.watch(appealFormControllerProvider);
    final isSubmitting = formState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi murojaat')),
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
            bodiesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) =>
                  const Text('Davlat organlarini yuklab bo\'lmadi'),
              data: (bodies) => DropdownButtonFormField<String>(
                initialValue: _recipientBodyId,
                decoration: const InputDecoration(
                  labelText: 'Qabul qiluvchi davlat organi',
                ),
                items: bodies
                    .map(
                      (b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _recipientBodyId = value),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Sarlavha'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Sarlavha kiritilishi shart'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Murojaat matni'),
              maxLines: 8,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Murojaat matni kiritilishi shart'
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
                  : const Text('Qoralamani saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}

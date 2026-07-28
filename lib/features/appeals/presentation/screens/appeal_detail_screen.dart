import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attachments/domain/entities/case_type.dart';
import '../../../attachments/presentation/providers/attachments_providers.dart';
import '../../../../core/error/failure_presentation.dart';
import '../../../../core/network/result.dart';
import '../../../../services/supabase/storage_service.dart';
import '../../domain/entities/appeal_status.dart';
import '../providers/appeals_providers.dart';
import '../widgets/appeal_status_badge.dart';

/// Murojaat tafsiloti — qoralama bo'lsa tahrirlash/yuborish, aks holda
/// faqat o'qish uchun (docs/ARCHITECTURE.md, "Case Lifecycle" bo'limi).
class AppealDetailScreen extends ConsumerStatefulWidget {
  const AppealDetailScreen({required this.appealId, super.key});

  final String appealId;

  @override
  ConsumerState<AppealDetailScreen> createState() =>
      _AppealDetailScreenState();
}

class _AppealDetailScreenState extends ConsumerState<AppealDetailScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _controllersInitialized = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    await ref
        .read(appealFormControllerProvider.notifier)
        .updateDraft(
          appealId: widget.appealId,
          title: _titleController.text.trim(),
          bodyText: _bodyController.text.trim(),
        );
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Murojaatni yuborish'),
        content: const Text(
          'Yuborilgandan so\'ng matnni tahrirlab bo\'lmaydi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(appealFormControllerProvider.notifier)
        .submit(widget.appealId);

    if (!mounted) return;
    final state = ref.read(appealFormControllerProvider);
    state.whenOrNull(
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeErrorForUser(error))),
      ),
    );
  }

  Future<void> _attachFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;

    if (file.size > CaseAttachmentStorage.maxFileSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fayl hajmi 10 MB dan oshmasligi kerak')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final contentType = switch (file.extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };

    final result = await ref
        .read(attachmentsRepositoryProvider)
        .upload(
          caseType: CaseType.appeal,
          caseId: widget.appealId,
          fileName: file.name,
          bytes: file.bytes!,
          contentType: contentType,
        );

    if (!mounted) return;
    setState(() => _isUploading = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.userMessage)),
      );
    } else {
      ref.invalidate(appealAttachmentsProvider(widget.appealId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appealAsync = ref.watch(appealDetailProvider(widget.appealId));
    final attachmentsAsync = ref.watch(
      appealAttachmentsProvider(widget.appealId),
    );
    final formState = ref.watch(appealFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Murojaat')),
      body: appealAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(describeErrorForUser(error))),
        data: (appeal) {
          if (!_controllersInitialized) {
            _titleController.text = appeal.title;
            _bodyController.text = appeal.bodyText;
            _controllersInitialized = true;
          }
          final isDraft = appeal.status == AppealStatus.draft;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppealStatusBadge(status: appeal.status),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                enabled: isDraft,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                enabled: isDraft,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Murojaat matni'),
              ),
              if (appeal.officialResponseText != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Rasmiy javob',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(appeal.officialResponseText!),
              ],
              const SizedBox(height: 24),
              if (isDraft) ...[
                OutlinedButton(
                  onPressed: formState.isLoading ? null : _saveDraft,
                  child: const Text('Qoralamani saqlash'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: formState.isLoading ? null : _submit,
                  child: const Text('Yuborish'),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Biriktirilgan fayllar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              attachmentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    Text('Fayllarni yuklab bo\'lmadi. ${describeErrorForUser(error)}'),
                data: (attachments) => Column(
                  children: [
                    for (final attachment in attachments)
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(attachment.fileName),
                        subtitle: Text(
                          '${(attachment.sizeBytes / 1024).toStringAsFixed(0)} KB',
                        ),
                      ),
                    if (attachments.isEmpty)
                      const Text('Hozircha fayl biriktirilmagan'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _attachFile,
                icon: _isUploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: const Text('Fayl biriktirish'),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_analyses/presentation/providers/ai_analyses_providers.dart';
import '../../../attachments/domain/entities/case_type.dart';
import '../../../attachments/presentation/providers/attachments_providers.dart';
import '../../../../core/error/failure_presentation.dart';
import '../../../../core/network/result.dart';
import '../../../../services/supabase/storage_service.dart';
import '../../../../services/supabase/supabase_client.dart';
import '../providers/disputes_providers.dart';
import '../widgets/dispute_status_badge.dart';

/// Nizo tafsiloti — initiator/respondent roliga qarab tegishli maydonni
/// tahrirlash, AI tahlili natijasini ko'rish va fayl biriktirish
/// (docs/ARCHITECTURE.md, "Case Lifecycle" bo'limi).
class DisputeDetailScreen extends ConsumerStatefulWidget {
  const DisputeDetailScreen({required this.disputeId, super.key});

  final String disputeId;

  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _statementController = TextEditingController();
  bool _controllersInitialized = false;
  bool _isUploading = false;

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _saveAsInitiator() async {
    await ref
        .read(disputeFormControllerProvider.notifier)
        .updateAsInitiator(
          disputeId: widget.disputeId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
  }

  Future<void> _saveRespondentStatement() async {
    await ref
        .read(disputeFormControllerProvider.notifier)
        .submitRespondentStatement(
          disputeId: widget.disputeId,
          statement: _statementController.text.trim(),
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
          caseType: CaseType.dispute,
          caseId: widget.disputeId,
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
      ref.invalidate(disputeAttachmentsProvider(widget.disputeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final disputeAsync = ref.watch(disputeDetailProvider(widget.disputeId));
    final attachmentsAsync = ref.watch(
      disputeAttachmentsProvider(widget.disputeId),
    );
    final aiAnalysesAsync = ref.watch(
      disputeAiAnalysesProvider(widget.disputeId),
    );
    final formState = ref.watch(disputeFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nizo')),
      body: disputeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(describeErrorForUser(error))),
        data: (dispute) {
          final isInitiator = dispute.initiatorId == _currentUserId;
          final isRespondent =
              dispute.respondentProfileId != null &&
              dispute.respondentProfileId == _currentUserId;

          if (!_controllersInitialized) {
            _titleController.text = dispute.title;
            _descriptionController.text = dispute.description;
            _statementController.text = dispute.respondentStatement ?? '';
            _controllersInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DisputeStatusBadge(status: dispute.status),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                enabled: isInitiator && dispute.status.isInitiatorEditable,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                enabled: isInitiator && dispute.status.isInitiatorEditable,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Sizning faktlaringiz',
                ),
              ),
              if (isInitiator && dispute.status.isInitiatorEditable) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: formState.isLoading ? null : _saveAsInitiator,
                  child: const Text('Saqlash'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Qarshi tomon bayonoti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _statementController,
                enabled: isRespondent && dispute.status.isRespondentEditable,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: isRespondent
                      ? 'Sizning bayonotingiz'
                      : (dispute.respondentStatement == null
                            ? 'Qarshi tomon hali javob bermagan'
                            : null),
                ),
              ),
              if (isRespondent && dispute.status.isRespondentEditable) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: formState.isLoading
                      ? null
                      : _saveRespondentStatement,
                  child: const Text('Bayonotni yuborish'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'AI tahlili',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              aiAnalysesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    Text('Yuklab bo\'lmadi. ${describeErrorForUser(error)}'),
                data: (analyses) => analyses.isEmpty
                    ? const Text(
                        'AI tahlili hali tayyor emas. Ikkala tomon fakti '
                        'to\'plangach, tahlil avtomatik boshlanadi.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final analysis in analyses) ...[
                            Text(analysis.analysisText),
                            if (analysis.legalBasisSummary != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  analysis.legalBasisSummary!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const Divider(),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
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

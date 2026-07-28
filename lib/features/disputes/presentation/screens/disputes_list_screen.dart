import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../providers/disputes_providers.dart';
import '../widgets/dispute_status_badge.dart';

/// "Nizolarim" ekrani — joriy foydalanuvchi initiator yoki respondent
/// bo'lgan barcha nizolar (docs/UI.md, "Navigation Structure" bo'limi).
class DisputesListScreen extends ConsumerWidget {
  const DisputesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(myDisputesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nizolarim')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.disputeCreate),
        child: const Icon(Icons.add),
      ),
      body: disputesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nizolarni yuklab bo\'lmadi. ${describeErrorForUser(error)}',
            ),
          ),
        ),
        data: (disputes) {
          if (disputes.isEmpty) {
            return const Center(
              child: Text('Hozircha nizolar yo\'q. "+" orqali yarating.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myDisputesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dispute = disputes[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      dispute.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      dispute.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: DisputeStatusBadge(status: dispute.status),
                    onTap: () => context.push(
                      RoutePaths.disputeDetailFor(dispute.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

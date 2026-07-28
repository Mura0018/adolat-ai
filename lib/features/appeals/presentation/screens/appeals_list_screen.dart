import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_presentation.dart';
import '../../../../router/route_paths.dart';
import '../providers/appeals_providers.dart';
import '../widgets/appeal_status_badge.dart';

/// "Murojaatlarim" ekrani — joriy foydalanuvchining barcha murojaatlari
/// (docs/UI.md, "Navigation Structure" bo'limi).
class AppealsListScreen extends ConsumerWidget {
  const AppealsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appealsAsync = ref.watch(myAppealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Murojaatlarim')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.appealCreate),
        child: const Icon(Icons.add),
      ),
      body: appealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Murojaatlarni yuklab bo\'lmadi. ${describeErrorForUser(error)}',
            ),
          ),
        ),
        data: (appeals) {
          if (appeals.isEmpty) {
            return const Center(
              child: Text('Hozircha murojaatlar yo\'q. "+" orqali yarating.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myAppealsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: appeals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final appeal = appeals[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      appeal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      appeal.bodyText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: AppealStatusBadge(status: appeal.status),
                    onTap: () => context.push(
                      RoutePaths.appealDetailFor(appeal.id),
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

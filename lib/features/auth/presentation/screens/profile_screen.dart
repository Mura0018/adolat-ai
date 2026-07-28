import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_role.dart';
import '../providers/auth_providers.dart';
import '../widgets/logout_confirmation_dialog.dart';

/// Profil ekrani — Fuqaro/Tashkilot/Admin uchun umumiy, faqat Tashkilot
/// rolida qo'shimcha yuridik ma'lumotlar ko'rsatiladi (docs/UI.md, "User
/// Roles": "Profil bo'limida qo'shimcha yuridik ma'lumotlar... yagona
/// farq").
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Profilni yuklab bo\'lmadi')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Sessiya topilmadi'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 28),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  switch (user.role) {
                    UserRole.citizen => 'Fuqaro',
                    UserRole.organization => 'Tashkilot',
                    UserRole.admin => 'Admin',
                  },
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              if (user.phoneNumber != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Telefon'),
                  subtitle: Text(user.phoneNumber!),
                ),
              if (user.organizationDetails case final org?) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Tashkilot nomi'),
                  subtitle: Text(org.legalName),
                ),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('STIR/INN'),
                  subtitle: Text(org.taxId),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Yuridik manzil'),
                  subtitle: Text(org.legalAddress),
                ),
                if (org.contactEmail != null)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Rasmiy aloqa email'),
                    subtitle: Text(org.contactEmail!),
                  ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => showLogoutConfirmationDialog(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Chiqish'),
              ),
            ],
          );
        },
      ),
    );
  }
}

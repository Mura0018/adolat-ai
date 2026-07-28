import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_paths.dart';

/// Ro'yxatdan o'tish turini tanlash ekrani (docs/UI.md, "Authentication
/// Screens": "Ro'yxatdan o'tish turi tanlash — Fuqaro yoki Tashkilot").
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ro\'yxatdan o\'tish')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kim sifatida ro\'yxatdan o\'tmoqchisiz?',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  context.push(RoutePaths.authRegisterCitizen),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Fuqaro sifatida'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.push(RoutePaths.authRegisterOrganization),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tashkilot sifatida'),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pushReplacement(RoutePaths.authLogin),
              child: const Text('Hisobingiz bormi? Kirish'),
            ),
          ],
        ),
      ),
    );
  }
}

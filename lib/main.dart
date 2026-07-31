import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/appeals/presentation/providers/appeals_providers.dart';
import 'services/offline/offline_providers.dart';
import 'services/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  // Mahalliy ma'lumotlar bazasi ilova ishga tushishida bir marta
  // ochiladi (ADR-007) -- Riverpod provayderi sinxron qiymat
  // qaytarishi kerak, baza ochish esa asinxron amal.
  final localDatabase = await openAppLocalDatabase();

  final container = ProviderContainer(
    overrides: [
      appLocalDatabaseProvider.overrideWithValue(localDatabase),
      // Feature'lar o'z sinxronizatsiya handlerlarini shu yerda
      // qo'shadi. Ataylab override orqali: `lib/services/` hech
      // qachon `lib/features/` ga bog'lanmasligi kerak (bog'liqlik
      // yo'nalishi -- `docs/ARCHITECTURE.md`, "Ichki Kod
      // Arxitekturasi").
      featureSyncHandlersProvider.overrideWith((ref) {
        return [ref.watch(appealsSyncOperationHandlerProvider)];
      }),
    ],
  );

  // Tarmoq kuzatuvi va sinxronizatsiya rejalashtiruvchisi ishga
  // tushiriladi (ADR-008): tarmoq qaytganda navbat avtomatik
  // yuboriladi, ilova ochilganda esa navbat albatta tekshiriladi
  // (`docs/ARCHITECTURE.md`, "Sync Engine" -> ishga tushish
  // shartlari).
  await container.read(networkStateMonitorProvider).start();
  final coordinator = container.read(syncCoordinatorProvider)..start();

  // Birinchi sikl ATAYLAB kutilmaydi: tarmoq sekin bo'lsa,
  // foydalanuvchi bo'sh ekranni ko'rib turardi. Sikl fon rejimida
  // davom etadi, natijasi `SyncState` orqali kuzatiladi.
  unawaited(coordinator.onAppStart());

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}

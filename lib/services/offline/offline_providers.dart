import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/offline/queue/local_store_offline_queue.dart';
import '../../core/offline/queue/offline_queue.dart';
import '../../core/offline/storage/local_store.dart';
import '../../core/offline/sync/queued_sync_engine.dart';
import '../../core/offline/sync/sync_coordinator.dart';
import '../../core/offline/sync/sync_engine.dart';
import '../local_database/app_local_database.dart';
import '../local_database/drift_local_store.dart';
import '../network_state/connectivity_plus_source.dart';
import '../network_state/reachability_aware_network_monitor.dart';
import '../network_state/reachability_reporting_sync_handler.dart';

/// Offline-first qatlamining **kompozitsiya ildizi** (Module 7D).
///
/// Bu yerda Module 6–7 davomida qurilgan barcha bo'laklar bir-biriga
/// ulanadi: doimiy saqlash (ADR-007), tarmoq signali (ADR-008),
/// navbat, dvigatel va koordinator.
///
/// **Nega `lib/services/` da:** bu fayl tashqi paketlarga
/// (`path_provider`, `drift`, `connectivity_plus`, Riverpod) tayanadi,
/// ya'ni u infratuzilma qatlamiga tegishli. `lib/core/offline/`
/// bularning hech biridan xabardor emas va shunday qolishi shart —
/// buni `test/core/offline/offline_architecture_boundary_test.dart`
/// majburlaydi.
///
/// **To'plam nomlari** — bitta Drift jadvali ichida ajratiladi
/// (`app_local_database.dart` izohiga qarang).
abstract final class OfflineCollections {
  static const String pendingOperations = 'pending_operations';
  static const String appeals = 'appeals';
}

/// Mahalliy ma'lumotlar bazasi.
///
/// **`main()` da override qilinadi** — bazani ochish asinxron amal
/// (`getApplicationDocumentsDirectory()`), Riverpod provayderi esa
/// sinxron qiymat qaytarishi kerak. Shu sababli baza ilova ishga
/// tushishida ochiladi va shu provayderga uzatiladi.
///
/// Testlarda `AppLocalDatabase.memory()` bilan override qilinadi —
/// ya'ni butun offline steki hech qanday fayl tizimisiz sinaladi.
final appLocalDatabaseProvider = Provider<AppLocalDatabase>((ref) {
  throw UnimplementedError(
    'appLocalDatabaseProvider `main()` da (yoki testda) override qilinishi shart — '
    '`openAppLocalDatabase()` ga qarang.',
  );
});

/// Diskdagi bazani ochadi (ilova ishga tushishida bir marta).
///
/// Fayl `<hujjatlar papkasi>/adolat_ai.sqlite` sifatida saqlanadi —
/// ya'ni ilova o'chirilganda o'chadi, lekin yangilanishlar orasida
/// saqlanib qoladi (`docs/ARCHITECTURE.md`, "Local Storage" →
/// *"Doimiylik"*).
Future<AppLocalDatabase> openAppLocalDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  // `package:path` ataylab ishlatilmadi -- u loyihada to'g'ridan-
  // to'g'ri bog'liqlik emas, va bitta yo'l birlashtirish uchun yangi
  // bog'liqlik qo'shish oqlanmaydi. Dart qo'llab-quvvatlaydigan
  // barcha platformalarda `/` ajratkichi to'g'ri ishlaydi.
  return AppLocalDatabase.file(File('${directory.path}/adolat_ai.sqlite'));
}

/// Navbat uchun mahalliy to'plam.
final pendingOperationsStoreProvider = Provider<LocalStore<Map<String, Object?>>>((ref) {
  return DriftLocalStore(
    ref.watch(appLocalDatabaseProvider),
    OfflineCollections.pendingOperations,
  );
});

/// Murojaatlarning mahalliy nusxasi.
final appealsCacheStoreProvider = Provider<LocalStore<Map<String, Object?>>>((ref) {
  return DriftLocalStore(ref.watch(appLocalDatabaseProvider), OfflineCollections.appeals);
});

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return LocalStoreOfflineQueue(ref.watch(pendingOperationsStoreProvider));
});

/// Tarmoq holati monitori (ADR-008: interfeys turtkisi + so'rov
/// natijalari).
///
/// `start()` `main()` da chaqiriladi — provayder qurilishi paytida
/// asinxron ish boshlanmasligi uchun.
final networkStateMonitorProvider = Provider<ReachabilityAwareNetworkMonitor>((ref) {
  final monitor = ReachabilityAwareNetworkMonitor(
    connectivitySource: ConnectivityPlusSource(),
  );
  ref.onDispose(monitor.dispose);
  return monitor;
});

/// Navbatdagi amallarni bajaruvchi handlerlar ro'yxati.
///
/// Har bir feature o'z handlerini shu yerga qo'shadi — hozircha
/// faqat `appeals` (Module 7C). Handler `ReachabilityReportingSyncHandler`
/// bilan o'raladi, shu bilan uning natijalari tarmoq monitoriga
/// "haqiqat manbai" sifatida yetib boradi (ADR-008).
final syncOperationHandlersProvider = Provider<List<SyncOperationHandler>>((ref) {
  final monitor = ref.watch(networkStateMonitorProvider);

  return [
    for (final handler in ref.watch(featureSyncHandlersProvider))
      ReachabilityReportingSyncHandler(inner: handler, monitor: monitor),
  ];
});

/// Feature'lar taqdim etadigan xom handlerlar.
///
/// Ataylab alohida provayder: feature'lar `lib/services/` ga
/// bog'lanmasligi uchun ular shu ro'yxatga override orqali qo'shiladi
/// (`app.dart`/`main.dart`), bu fayl esa ularni faqat o'raydi.
final featureSyncHandlersProvider = Provider<List<SyncOperationHandler>>((ref) {
  return const [];
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = QueuedSyncEngine(
    queue: ref.watch(offlineQueueProvider),
    handlers: ref.watch(syncOperationHandlersProvider),
    networkMonitor: ref.watch(networkStateMonitorProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Offline qatlamining yagona tashqi kirish nuqtasi (Module 6C).
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    engine: ref.watch(syncEngineProvider),
    queue: ref.watch(offlineQueueProvider),
    networkMonitor: ref.watch(networkStateMonitorProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

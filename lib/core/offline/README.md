# core/offline/ — Offline-First poydevori (Module 6, Phase 6A–6C)

`docs/ARCHITECTURE.md`ning **"Offline-First Architecture"**, **"Local Storage"**, **"Sync Engine"** va **"Conflict Resolution"** bo'limlarining kod darajasidagi ifodasi.

## Ko'lam (Phase 6A–6C)

**Faqat arxitektura va shartnomalar.** Bu bosqichda ataylab YO'Q:

- HTTP/WebSocket chaqiruvi, Supabase SDK, backend yoki Edge Function kodi;
- AI provayder integratsiyasi va API kalitlari;
- UI o'zgarishlari (`presentation/` qatlamiga umuman tegilmagan);
- yangi paket bog'liqligi (`pubspec.yaml` o'zgarmagan);
- doimiy (persistent) saqlash implementatsiyasi — saqlash paketi tanlovi alohida qaror (ADR) sifatida rasmiylashtirilishi kerak.

Har bir shartnoma yo implementatsiyasiz interfeys, yo xotiradagi (in-memory) poydevor implementatsiyasi bilan keladi — `ai_service/`dagi (Module 4–5) bir xil naqsh.

## Tuzilma

```
core/offline/
├── storage/       LocalStore<T>/LocalStorage (interfeys) + InMemory implementatsiyasi
├── queue/         PendingOperation (model + seriyalash) + OfflineQueue (interfeys)
│                  + InMemory navbat + LocalStoreOfflineQueue (doimiylik yo'li) [6C]
├── network/       NetworkStatus/NetworkStatusChange, NetworkStateMonitor (interfeys)
│                  + InMemory (boshqariladigan) implementatsiya            [6B]
├── sync/          SyncState, SyncOperationOutcome, SyncOperationHandler,
│                  SyncEngine (interfeys), SyncBackoffPolicy (xolis qoida),
│                  QueuedSyncEngine (orkestratsiya, I/O YO'Q),
│                  SyncScheduler (qachon ishga tushirish)                  [6B]
│                  SyncCoordinator (yagona kirish nuqtasi, signal
│                  birlashtirish)                                          [6C]
├── conflict/      SyncConflict, ConflictResolution (sealed),
│                  ConflictResolutionStrategy + Default implementatsiyasi
└── repositories/  LocalDataSource<T>, OfflineCapableRepository, RecordSyncStatus
```

## Vazifalar taqsimoti

| Komponent | Javob beradigan savol |
|---|---|
| `NetworkStateMonitor` | Tarmoq bormi? (**sezuv organi** — saqlamaydi, sinxronlamaydi) |
| `SyncScheduler` | **Qachon** sinxronlash kerak? |
| `SyncEngine` | Bitta siklni **qanday** bajarish kerak? |
| `SyncOperationHandler` | Bitta amalni serverga **qanday** yuborish kerak? (yagona tarmoq nuqtasi) |
| `SyncCoordinator` | Tashqi dunyo bilan **yagona** aloqa nuqtasi; signallar yo'qolmasligi |
| `ConflictResolutionStrategy` | Server bilan mos kelmaganda **nima qilish** kerak? |

## Asosiy almashtirish nuqtalari

| Chegara | Hozir | Kelgusida |
|---|---|---|
| `LocalStore` | `InMemoryLocalStore` | **Drift** (ADR-007, qabul qilingan 2026-07-31) |
| `SyncOperationHandler` | Yo'q (testda fake) | Supabase orqali haqiqiy yuborish |
| `NetworkStateMonitor` | `InMemoryNetworkStateMonitor` (qo'lda boshqariladi) | **connectivity_plus (turtki) + so'rov natijalari (haqiqat)** (ADR-008, qabul qilingan 2026-07-31) |
| `ConflictResolutionStrategy` | `DefaultConflictResolutionStrategy` | Feature'ga xos qoida kerak bo'lsa |

**Muhim:** butun offline yadrosi "serverga qanday murojaat qilinadi" bilimini FAQAT `SyncOperationHandler` ortida saqlaydi — shuning uchun 6A'da tarmoq kodi umuman yozilmagan holda ham navbat, tartib, qayta urinish va ziddiyat qoidalari to'liq qurilgan va sinalgan.

## Avtomatik chegara nazorati

`test/core/offline/offline_architecture_boundary_test.dart` har bir faylni skanerlaydi va quyidagilarni CI darajasida taqiqlaydi: `dio`/`http`/WebSocket, Supabase SDK, Flutter UI/Riverpod, `ai_service/`/`ai_client/`, `dart:io`, `features/` importlari, hisob ma'lumoti/token bilan ishlash va `adolat_ai`dan boshqa har qanday paket.

## Mavjud kodga ta'siri

**Nol.** Hech bir feature bu interfeyslarga hali ulanmagan — `lib/features/` va `lib/services/` o'zgarmagan. Ulash keyingi bosqich ishi.

## Phase 6C — yakunlash

6A/6B integratsiyasida topilgan bo'shliqlar yopildi:

| Bo'shliq | Yechim |
|---|---|
| `enqueue` boshlangan amal ustiga yozardi (takroriy yuborish xavfi) | `inProgress`/`completed` amal himoyalangan |
| Bloklangan ota-amalga bog'liq amal mangu kutardi | Kaskad bloklash, sabab bilan |
| `needsAttention`dan chiqish yo'li yo'q edi | `retryNow()` — foydalanuvchi qarori |
| Sikl davomida kelgan signal yo'qolardi | `SyncCoordinator` birlashtiradi |
| Navbatni saqlab bo'lmasdi | `toJson`/`fromJson` + `LocalStoreOfflineQueue` |

Ikkala navbat implementatsiyasi **bir xil shartnoma testidan** o'tadi (`test/core/offline/offline_queue_contract_test.dart`) — doimiy saqlashga o'tishda xatti-harakat farqi darhol ushlanadi.

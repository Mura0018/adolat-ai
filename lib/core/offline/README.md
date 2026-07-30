# core/offline/ — Offline-First poydevori (Module 6, Phase 6A)

`docs/ARCHITECTURE.md`ning **"Offline-First Architecture"**, **"Local Storage"**, **"Sync Engine"** va **"Conflict Resolution"** bo'limlarining kod darajasidagi ifodasi.

## Ko'lam (Phase 6A)

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
├── queue/         PendingOperation (model) + OfflineQueue (interfeys) + InMemory navbat
├── sync/          SyncState, SyncOperationOutcome, SyncOperationHandler,
│                  SyncEngine (interfeys), SyncBackoffPolicy (xolis qoida),
│                  QueuedSyncEngine (orkestratsiya, I/O YO'Q)
├── conflict/      SyncConflict, ConflictResolution (sealed),
│                  ConflictResolutionStrategy + Default implementatsiyasi
└── repositories/  LocalDataSource<T>, OfflineCapableRepository, RecordSyncStatus
```

## Asosiy almashtirish nuqtalari

| Chegara | Hozir | Kelgusida |
|---|---|---|
| `LocalStore` | `InMemoryLocalStore` | Doimiy saqlash (paket ADR bilan tanlanadi) |
| `SyncOperationHandler` | Yo'q (testda fake) | Supabase orqali haqiqiy yuborish |
| `isOnline` (`QueuedSyncEngine`) | `() => true` | Network State Handling (6B) |
| `ConflictResolutionStrategy` | `DefaultConflictResolutionStrategy` | Feature'ga xos qoida kerak bo'lsa |

**Muhim:** butun offline yadrosi "serverga qanday murojaat qilinadi" bilimini FAQAT `SyncOperationHandler` ortida saqlaydi — shuning uchun 6A'da tarmoq kodi umuman yozilmagan holda ham navbat, tartib, qayta urinish va ziddiyat qoidalari to'liq qurilgan va sinalgan.

## Avtomatik chegara nazorati

`test/core/offline/offline_architecture_boundary_test.dart` har bir faylni skanerlaydi va quyidagilarni CI darajasida taqiqlaydi: `dio`/`http`/WebSocket, Supabase SDK, Flutter UI/Riverpod, `ai_service/`/`ai_client/`, `dart:io`, `features/` importlari, hisob ma'lumoti/token bilan ishlash va `adolat_ai`dan boshqa har qanday paket.

## Mavjud kodga ta'siri

**Nol.** Hech bir feature bu interfeyslarga hali ulanmagan — `lib/features/` va `lib/services/` o'zgarmagan. Ulash keyingi bosqich ishi.

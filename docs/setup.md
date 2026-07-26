# O'rnatish va ishga tushirish

Bu skelet Flutter SDK o'rnatilmagan muhitda tayyorlangan (faqat Dart-tomon fayllari — `lib/`, `pubspec.yaml`, hujjatlar). Loyihani birinchi marta ishga tushirishdan oldin quyidagi qadamlarni bajaring.

## 1. Flutter SDK o'rnatish

Agar hali o'rnatilmagan bo'lsa: https://docs.flutter.dev/get-started/install

Tekshirish:

```bash
flutter --version
flutter doctor
```

## 2. Platforma papkalarini generatsiya qilish (android/ios/web)

Bu skeletda `android/`, `ios/`, `web/` papkalari **yo'q** — ular qo'lda soxta yaratilmagan (bu xato va ishonchsiz bo'lardi). Loyiha ildizida quyidagini ishga tushiring:

```bash
flutter create --platforms=android,ios,web --org com.adolatai .
```

Bu buyruq mavjud fayllarni (README.md, pubspec.yaml, lib/) qayta yozib yubormaydi — faqat yetishmayotgan platforma papkalarini qo'shadi.

## 3. Paketlarni o'rnatish

```bash
flutter pub get
```

## 4. Kod generatsiyasi (Freezed / json_serializable)

Hozircha `lib/` ichida `@freezed` bilan yozilgan haqiqiy model yo'q (skeletda biznes logika yo'qligi sababli), lekin birinchi feature qo'shilganda:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 5. Lokalizatsiya generatsiyasi

```bash
flutter gen-l10n
```

Bu `lib/localization/*.arb` fayllaridan `AppLocalizations` klassini generatsiya qiladi. Generatsiyadan so'ng `lib/app.dart`dagi `localizationsDelegates` ro'yxatiga `AppLocalizations.delegate` qo'shing (fayldagi izohga qarang).

## 6. Environment o'zgaruvchilarini berish

Supabase va API kalitlari `--dart-define` orqali beriladi (`.env` fayli commit qilinmaydi):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxxx \
  --dart-define=API_BASE_URL=https://api.adolat.ai
```

## 7. Ishga tushirish

```bash
flutter run
```

## Qisqacha buyruqlar ketma-ketligi

```bash
flutter create --platforms=android,ios,web --org com.adolatai .
flutter pub get
flutter gen-l10n
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

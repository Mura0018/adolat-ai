# Arxitektura

Adolat AI **feature-first + Clean Architecture** tamoyiliga asoslanadi. Maqsad: biznes logikani (domain) UI'dan va tashqi kutubxonalardan (Supabase, Dio) ajratib turish — shunda har bir qatlam mustaqil ravishda almashtirilishi va test qilinishi mumkin.

## Qatlamlar (har bir `features/<nom>/` ichida)

```
presentation  →  domain  ←  data
```

- **`domain/`** — markaz. Sof Dart, hech qanday Flutter/Supabase/Dio importi yo'q.
  - `entities/` — biznes obyektlari (Freezed bilan immutable)
  - `repositories/` — abstrakt shartnoma (interface), masalan `abstract class AppealsRepository`
  - `usecases/` — bitta aniq amal (masalan `SubmitAppealUseCase`), Single Responsibility
- **`data/`** — `domain/repositories/` shartnomasini amalga oshiradi.
  - `datasources/` — Supabase/API bilan bevosita ishlaydi (`services/supabase/` dan foydalanadi)
  - `models/` — Freezed DTO (JSON serialization bilan), `domain/entities/`ga xaritalanadi
  - `repositories/` — `domain/repositories/` interfeysining implementatsiyasi, datasource xatoliklarini `Failure`ga aylantiradi
- **`presentation/`** — UI va holat boshqaruvi.
  - `providers/` — Riverpod providerlar, `usecases/`ni chaqiradi
  - `screens/` — to'liq ekranlar (GoRouter shu yerga ishora qiladi)
  - `widgets/` — shu feature'ga xos widgetlar

## Xatoliklarni qayta ishlash

`data` qatlami `Exception` tashlaydi → `repository` implementatsiyasi uni ushlab `core/error/`dagi `Failure` sealed union'iga aylantiradi → `domain`/`presentation` faqat `Failure` bilan ishlaydi, hech qachon xom exception bilan emas.

## Holat boshqaruvi — Riverpod

Har bir feature o'z providerlarini `presentation/providers/` ichida e'lon qiladi. Global/infratuzilma providerlar (`dioClientProvider`, `secureStorageServiceProvider`) `services/` ichida joylashadi va istalgan feature tomonidan `ref.watch`/`ref.read` orqali ishlatiladi.

## Immutable modellar — Freezed

Barcha `domain/entities/` va `data/models/` klasslari `@freezed` annotatsiyasi bilan yoziladi:

```dart
@freezed
class Appeal with _$Appeal {
  const factory Appeal({
    required String id,
    required String title,
  }) = _Appeal;

  factory Appeal.fromJson(Map<String, dynamic> json) => _$AppealFromJson(json);
}
```

Generatsiya qilingan `*.freezed.dart`/`*.g.dart` fayllar `.gitignore`ga kiritilgan — ular `dart run build_runner build` orqali lokal generatsiya qilinadi (`docs/setup.md`ga qarang).

## Marshrutlash — GoRouter

Yagona `GoRouter` konfiguratsiyasi `router/app_router.dart`da. Har bir feature marshruti shu yerga qo'shiladi, ekranning o'zi feature ichida qoladi.

## Nega bu tuzilma?

- **Test qilinishi oson** — `domain/` tashqi kutubxonalarga bog'liq emas, shuning uchun mock'siz unit test yozish mumkin.
- **Almashtirilishi oson** — Supabase o'rniga boshqa backend kerak bo'lsa, faqat `data/` qatlami o'zgaradi, `domain`/`presentation` tegilmaydi.
- **Katta jamoa uchun mos** — feature-first tuzilma bir nechta dasturchi parallel, bir-biriga xalaqit bermay ishlashiga imkon beradi.

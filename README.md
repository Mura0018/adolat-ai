# Adolat AI

Platforma maqsadi:
O'zbekiston fuqarolari va tashkilotlariga huquqiy yordam, adolat, tartib va qonuniy murojaatlarni soddalashtirish.

## Texnologiyalar

- **Flutter** — Android, iOS, Web (bitta kod bazasi)
- **Supabase** — backend (auth, database, storage)
- **Riverpod** — holat boshqaruvi
- **GoRouter** — deklarativ marshrutlash
- **Freezed** — immutable data modellari
- **Dio** — HTTP client
- **Flutter Secure Storage** — maxfiy ma'lumotlarni xavfsiz saqlash

## Arxitektura

Loyiha **feature-first + Clean Architecture** tamoyiliga asoslanadi: har bir biznes imkoniyat (`lib/features/<nom>/`) `data` / `domain` / `presentation` qatlamlariga bo'lingan holda joylashadi. Batafsil: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi.

## Papka strukturasi

| Papka | Vazifasi |
|---|---|
| `lib/core/` | Feature'ga bog'liq bo'lmagan infratuzilma (konstantalar, xatoliklar, konfiguratsiya) |
| `lib/features/` | Biznes imkoniyatlar — Clean Architecture uch qatlami bilan |
| `lib/shared/` | Bir nechta feature orasida qayta ishlatiladigan kod |
| `lib/services/` | Tashqi integratsiyalar — Dio, Supabase, Secure Storage |
| `lib/models/` | Umumiy data modellari |
| `lib/widgets/` | Qayta ishlatiladigan UI komponentlar (dizayn-tizimi) |
| `lib/theme/` | Ranglar, tipografiya, `ThemeData` |
| `lib/router/` | `GoRouter` konfiguratsiyasi |
| `lib/localization/` | `.arb` tarjima fayllari |
| `assets/` | Rasmlar, ikonkalar, shriftlar |
| `docs/` | Arxitektura va sozlash hujjatlari |
| `test/` | Avtomatik testlar |

Har bir papka ichida o'ziga xos `README.md` mavjud. To'liq jadval: [`docs/folder_structure.md`](docs/folder_structure.md).

## O'rnatish

Loyiha hozircha faqat Dart-tomon skeleti (`lib/`, `pubspec.yaml`) sifatida tayyorlangan — hech qanday biznes logika yozilmagan. Platforma papkalari (`android/`, `ios/`, `web/`) va ishga tushirish qadamlari uchun: [`docs/SETUP.md`](docs/SETUP.md), "Amaliy O'rnatish Qadamlari" bo'limi.

## Holat

Loyiha boshlang'ich (skeleton) bosqichida — struktura tayyor, biznes logika hali qo'shilmagan.

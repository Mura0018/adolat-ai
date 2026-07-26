# Papka strukturasi

| Papka | Vazifasi |
|---|---|
| `lib/core/` | Feature'ga bog'liq bo'lmagan infratuzilma: konstantalar, xatolik bazaviy klasslari, tarmoq shartnomalari, util funksiyalar, environment konfiguratsiyasi |
| `lib/features/` | Har bir biznes imkoniyat — `data/domain/presentation` uch qatlamiga bo'lingan holda (Clean Architecture) |
| `lib/shared/` | Bir nechta feature orasida qayta ishlatiladigan kengaytmalar, mixinlar, umumiy validatorlar |
| `lib/services/` | Tashqi kutubxona integratsiyalari — Dio client, Supabase client, Secure Storage wrapper |
| `lib/models/` | Bir nechta feature orasida qayta ishlatiladigan umumiy data modellari (Freezed) |
| `lib/widgets/` | Dizayn-tizimi — qayta ishlatiladigan umumiy UI komponentlar |
| `lib/theme/` | Ranglar, tipografiya, `ThemeData` (light/dark) |
| `lib/router/` | `GoRouter` konfiguratsiyasi va marshrut konstantalari |
| `lib/localization/` | `.arb` tarjima fayllari (o'zbek, ingliz) |
| `assets/` | Statik resurslar — rasmlar, ikonkalar, shriftlar |
| `docs/` | Loyiha hujjatlari — arxitektura, struktura, sozlash bo'yicha qo'llanma |
| `test/` | Avtomatik testlar (`lib/` strukturasini oynadek aks ettiradi) |

Har bir papka ichida alohida `README.md` mavjud — u yerda shu papkaning aniqroq vazifasi va ichki tuzilmasi tushuntirilgan.

Batafsil arxitektura tushuntirishi uchun: [`architecture.md`](./architecture.md). O'rnatish va ishga tushirish uchun: [`setup.md`](./setup.md).

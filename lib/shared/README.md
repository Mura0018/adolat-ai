# shared/

Bir nechta feature orasida qayta ishlatiladigan, lekin `core/` darajasidagi "infratuzilma" hisoblanmaydigan kod: kengaytmalar, mixinlar, umumiy (feature'ga xos bo'lmagan) validatorlar.

| Papka | Vazifasi |
|---|---|
| `extensions/` | `BuildContext`, `String`, `DateTime` va boshqa turlar uchun umumiy Dart kengaytmalari |
| `mixins/` | Bir nechta feature/widget orasida qayta ishlatiladigan mixinlar |
| `validators/` | Umumiy forma validatsiya qoidalari (email, telefon raqami formati va h.k.) — biznesga xos qoidalar emas |

Farqi `core/`dan: `core/` — sof infratuzilma (hech qanday UI/feature konteksti yo'q), `shared/` — ko'proq presentation/feature qatlamlariga yaqin, lekin bir nechta feature tomonidan ishlatiladigan umumiy kod.

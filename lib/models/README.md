# models/

Bir nechta feature orasida qayta ishlatiladigan **umumiy** data modellari (masalan, `PaginatedResponse<T>`, `AppUser` — agar u bir nechta feature'da ishlatilsa).

Muayyan feature'ga xos modellar (masalan, "murojaat" modeli) bu yerda emas, tegishli `features/<nom>/data/models/` ichida joylashadi. Konventsiya: barcha modellar `Freezed` + `json_serializable` yordamida immutable va JSON-serializable qilib yoziladi (`@freezed` annotatsiyasi, `fromJson`/`toJson`). Batafsil: [`docs/architecture.md`](../../docs/architecture.md).

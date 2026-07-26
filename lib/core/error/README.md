# core/error/

Butun ilova bo'ylab ishlatiladigan xatolik-qayta ishlash shartnomalari: `Failure` bazaviy klassi (odatda `Freezed` sealed union sifatida — masalan `NetworkFailure`, `ServerFailure`, `CacheFailure`) va `Exception` klasslari.

Konventsiya: `data` qatlami exception tashlaydi → `repository` uni ushlab `Failure`ga aylantiradi → `domain`/`presentation` qatlami faqat `Failure` bilan ishlaydi. Batafsil: [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md), "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi.

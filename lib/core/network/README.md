# core/network/

Tarmoq qatlami uchun feature'ga bog'liq bo'lmagan umumiy shartnomalar: masalan, `Result<T>`/`Either<Failure, T>` kabi natija turlari, umumiy `ApiException` xarita qilish qoidalari.

Haqiqiy Dio client konfiguratsiyasi (`lib/services/network/dio_client.dart`) — bu yerda emas, `services/` ichida joylashgan, chunki u konkret tashqi kutubxona bilan integratsiya hisoblanadi.

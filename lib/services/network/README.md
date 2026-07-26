# services/network/

Dio HTTP client'ining markaziy konfiguratsiyasi: bazaviy URL, timeout, interceptorlar (logging, autentifikatsiya sarlavhasi qo'shish, xatoliklarni umumiy formatga xaritalash).

Bu yerda **hech qanday endpoint chaqiruvi yo'q** — aniq API so'rovlari tegishli `features/<nom>/data/datasources/` ichida yoziladi, ular shu yerdagi `dioClientProvider`dan foydalanadi.

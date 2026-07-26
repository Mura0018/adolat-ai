# services/secure_storage/

`flutter_secure_storage` ustidan umumiy CRUD wrapper — token, refresh token va boshqa maxfiy ma'lumotlarni platforma darajasidagi xavfsiz xotirada (Android Keystore / iOS Keychain) saqlash uchun.

Bu yerda **hech qanday biznes qoidasi yo'q** (masalan, "token muddati o'tganda nima qilish kerak" — bu `features/auth/` mas'uliyati). Faqat generik `read`/`write`/`delete` amallari.

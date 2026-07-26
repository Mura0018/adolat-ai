# services/

Tashqi kutubxonalar/platformalar bilan integratsiya qiluvchi infratuzilma xizmatlari — bular "qanday qilib biror narsaga ulanish" haqida, "nima qilish kerak" (biznes logika) haqida emas.

| Papka | Vazifasi |
|---|---|
| `network/` | Dio client sozlamalari, interceptorlar (autentifikatsiya sarlavhasi, logging, xatolik xaritalash) |
| `supabase/` | Supabase client'ni ishga tushirish (initialize) — auth/database/storage uchun yagona kirish nuqtasi |
| `secure_storage/` | `flutter_secure_storage` ustidan umumiy CRUD wrapper (token, maxfiy ma'lumotlarni saqlash uchun) |

Bu papkadagi kod feature'lardan mustaqil — masalan `SupabaseClientService` "qanday ulanish"ni biladi, lekin "qaysi jadvaldan nima o'qish kerak"ligini bilmaydi (bu `features/<nom>/data/datasources/` mas'uliyati).

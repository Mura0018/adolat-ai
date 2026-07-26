# services/supabase/

Supabase client'ini ishga tushirish (initialize) uchun yagona joy. `main.dart` ilova ishga tushishida `SupabaseService.initialize()` ni chaqiradi, so'ng butun ilova bo'ylab `Supabase.instance.client` orqali auth/database/storage'ga kirish mumkin bo'ladi.

Bu yerda **hech qanday jadval so'rovi yo'q** — aniq so'rovlar (masalan, `from('appeals').select()`) tegishli `features/<nom>/data/datasources/` ichida yoziladi.

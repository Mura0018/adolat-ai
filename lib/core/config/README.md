# core/config/

Ilova konfiguratsiyasi: environment o'zgaruvchilari (Supabase URL/anon key kabi), build flavor sozlamalari (`dev`/`staging`/`prod`).

`env_config.dart` — environment kalitlari uchun placeholder konstantalar. Haqiqiy qiymatlar `--dart-define` yoki `.env` fayli orqali beriladi (`.env` repo'ga commit qilinmaydi, `.gitignore`da istisno qilingan).

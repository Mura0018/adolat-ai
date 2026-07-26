# core/

Ilovaning istalgan feature'iga bog'liq bo'lmagan, butun ilova bo'ylab ishlatiladigan infratuzilma kodi. Bu yerda **hech qanday biznes logika** bo'lmaydi — faqat umumiy, qayta ishlatiladigan asos.

| Papka | Vazifasi |
|---|---|
| `constants/` | Butun ilova bo'ylab ishlatiladigan o'zgarmas qiymatlar (masalan, timeout'lar, sahifalash o'lchamlari, regex naqshlar) |
| `error/` | Xatolik/`Failure` bazaviy klasslari va umumiy xatolik-qayta ishlash shartnomalari (feature'larga xos emas) |
| `network/` | Tarmoq qatlami uchun umumiy shartnoma va bazaviy klasslar (masalan, `Result`/`Either` turlari, umumiy interceptor kontraktlari) |
| `utils/` | Feature'ga bog'liq bo'lmagan sof funksiyalar va kengaytmalar (formatlash, validatsiya yordamchilari) |
| `config/` | Ilova konfiguratsiyasi — environment o'zgaruvchilari, flavor sozlamalari |

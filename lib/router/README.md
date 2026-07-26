# router/

`GoRouter` konfiguratsiyasi — butun ilova bo'ylab yagona marshrutlash manbai.

| Fayl | Vazifasi |
|---|---|
| `route_paths.dart` | Marshrut nomi/yo'l konstantalari (qattiq kodlangan satrlarni oldini olish uchun) |
| `app_router.dart` | `GoRouter` instance'i — har bir marshrut tegishli feature'ning `presentation/screens/` papkasidagi ekranga ishora qiladi |

Feature qo'shilganda, uning marshruti shu yerga (`app_router.dart`) qo'shiladi, lekin ekranning o'zi tegishli `features/<nom>/presentation/screens/` ichida qoladi.

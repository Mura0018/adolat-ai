# test/

Avtomatik testlar uchun papka. `lib/` strukturasini oynadek aks ettiradi (masalan `lib/features/auth/domain/usecases/login.dart` uchun test `test/features/auth/domain/usecases/login_test.dart` bo'ladi).

| Test turi | Joylashuvi |
|---|---|
| Unit testlar (domain/usecases, core/utils) | `test/<lib strukturasi>/` |
| Widget testlar | `test/<feature>/presentation/widgets/` |
| Integratsiya testlari | `integration_test/` (kerak bo'lganda alohida qo'shiladi) |

Hozircha testlar yozilmagan — bu skeletda biznes logika yo'q, shuning uchun test qilinadigan narsa yo'q.

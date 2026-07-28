/// `UserContext.role` uchun tur-xavfsiz qiymat.
///
/// **Nega `lib/features/auth/domain/entities/user_role.dart`dagi
/// `UserRole`dan foydalanilmagan:** `ai_service/` `lib/`ga hech qachon
/// bog'liq bo'lmasligi kerak (`docs/adr/ADR-006`, "Repository chegarasi
/// — istisnosiz"; `ai_service/README.md`). Ikkala enum kontseptual
/// jihatdan bir xil (`profiles.role`ni aks ettiradi — `docs/DATABASE.md`,
/// 1-jadval), lekin bu qasddan takrorlanish — ikkita mustaqil kod bazasi
/// (Flutter klient va backend AI xizmati) orasidagi chegarani saqlash
/// narxi.
enum AIUserRole { citizen, organization, admin }

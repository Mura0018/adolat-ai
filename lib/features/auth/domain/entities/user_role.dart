/// `public.profiles.role` enum'iga mos domain qiymati
/// (docs/DATABASE.md, 1-jadval; docs/SECURITY.md, "Avtorizatsiya (Authorization) — 3 rol").
enum UserRole {
  citizen('citizen'),
  organization('organization'),
  admin('admin');

  const UserRole(this.dbValue);

  /// Supabase'dagi enum qiymati bilan bir xil satr — datasource shu orqali
  /// serialize/deserialize qiladi.
  final String dbValue;

  static UserRole fromDbValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.dbValue == value,
      orElse: () => throw ArgumentError('Noma\'lum profiles.role qiymati: $value'),
    );
  }
}

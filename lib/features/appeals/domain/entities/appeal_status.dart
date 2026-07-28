/// `public.appeal_status` enum'iga mos domain qiymati
/// (docs/DATABASE.md, 5-jadval; supabase/migrations/20260726000001_...sql).
enum AppealStatus {
  draft('draft'),
  submitted('submitted'),
  inReview('in_review'),
  answered('answered'),
  rejected('rejected'),
  closed('closed');

  const AppealStatus(this.dbValue);

  /// Supabase'dagi enum qiymati bilan bir xil satr — datasource shu orqali
  /// serialize/deserialize qiladi.
  final String dbValue;

  static AppealStatus fromDbValue(String value) {
    return AppealStatus.values.firstWhere(
      (status) => status.dbValue == value,
      orElse: () =>
          throw ArgumentError('Noma\'lum appeal_status qiymati: $value'),
    );
  }

  /// Muallif matnni tahrirlashi mumkin bo'lgan yagona holat
  /// (docs/DATABASE.md, 5-jadval "RLS talablari"; supabase/migrations/
  /// 20260726000002_rls_policies.sql, appeals_update siyosati).
  bool get isEditableByAuthor => this == AppealStatus.draft;
}

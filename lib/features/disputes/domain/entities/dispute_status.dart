/// `public.dispute_status` enum'iga mos domain qiymati
/// (docs/DATABASE.md, 6-jadval; supabase/migrations/20260726000001_...sql).
enum DisputeStatus {
  open('open'),
  aiAnalyzing('ai_analyzing'),
  aiAnalyzed('ai_analyzed'),
  resolved('resolved'),
  closed('closed');

  const DisputeStatus(this.dbValue);

  final String dbValue;

  static DisputeStatus fromDbValue(String value) {
    return DisputeStatus.values.firstWhere(
      (status) => status.dbValue == value,
      orElse: () =>
          throw ArgumentError('Noma\'lum dispute_status qiymati: $value'),
    );
  }

  /// Status o'zgarishi FAQAT service role/admin orqali amalga oshadi
  /// (docs/DATABASE.md, 6-jadval "RLS talablari"; supabase/migrations/
  /// 20260726000002_rls_policies.sql, disputes_update_* siyosatlari) —
  /// klient hech qachon bu qiymatni to'g'ridan-to'g'ri o'zgartira olmaydi.
  bool get isInitiatorEditable => this == DisputeStatus.open;

  bool get isRespondentEditable =>
      this == DisputeStatus.open || this == DisputeStatus.aiAnalyzing;
}

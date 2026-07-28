/// `public.case_type` enum'iga mos domain qiymati (docs/DATABASE.md,
/// "Umumiy konventsiyalar" bo'limidagi "mutually exclusive FK" naqshi).
///
/// `attachments`, `case_status_history` va `ai_analyses` jadvallari shu
/// qiymat orqali `appeals`/`disputes`dan aynan bittasiga bog'lanadi — shu
/// sababli bu tur `attachments` feature'ida markazlashtirilgan va
/// `disputes` feature'i (AI tahlilini ko'rish uchun) undan qayta
/// foydalanadi.
enum CaseType {
  appeal('appeal'),
  dispute('dispute');

  const CaseType(this.dbValue);

  final String dbValue;

  static CaseType fromDbValue(String value) {
    return CaseType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => throw ArgumentError('Noma\'lum case_type qiymati: $value'),
    );
  }
}

/// `public.dispute_respondent_type` enum'iga mos domain qiymati
/// (docs/DATABASE.md, 6-jadval).
enum DisputeRespondentType {
  citizen('citizen'),
  organization('organization'),
  unregistered('unregistered');

  const DisputeRespondentType(this.dbValue);

  final String dbValue;

  static DisputeRespondentType fromDbValue(String value) {
    return DisputeRespondentType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => throw ArgumentError(
        'Noma\'lum dispute_respondent_type qiymati: $value',
      ),
    );
  }
}

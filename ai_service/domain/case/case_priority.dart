/// Ishning navbatdagi o'rni (triage) -- huquqiy og'irlik BAHOSI EMAS
/// (talab: "Do not implement legal decisions") -- faqat operatsion
/// tartib: qaysi ish avval ko'rib chiqilishi kerak.
///
/// Standart qiymat -- `normal` (`Case.create()`, `domain/repositories/
/// case_repository.dart`ga qarang) -- aniq ko'rsatilmasa, hech qanday
/// ish "avtomatik" shoshilinch deb belgilanmasligi kerak.
enum CasePriority { low, normal, high, urgent }

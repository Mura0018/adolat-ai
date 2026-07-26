/// Environment konfiguratsiyasi uchun placeholder kalitlar.
///
/// Qiymatlar build vaqtida `--dart-define=SUPABASE_URL=...` orqali beriladi.
/// Bu klass hech qanday haqiqiy qiymatni o'zida saqlamaydi — faqat kalitlar
/// shartnomasini belgilaydi.
abstract final class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}

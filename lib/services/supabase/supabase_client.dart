import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';
import 'secure_gotrue_storage.dart';

/// Supabase client'ini ishga tushirish uchun yupqa (thin) wrapper.
///
/// Bu klass faqat "qanday ulanish"ni biladi — qaysi jadvaldan nima o'qish
/// kerakligi haqida bilmaydi (bu `features/<nom>/data/datasources/`
/// mas'uliyati).
abstract final class SupabaseService {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
      // docs/SECURITY.md, "Autentifikatsiya": tokenlar oddiy
      // SharedPreferences'da emas, Flutter Secure Storage orqali
      // saqlanishi shart — supabase_flutter'ning standart storage'i
      // (SharedPreferencesLocalStorage/SharedPreferencesGotrueAsyncStorage)
      // buni buzadi, shuning uchun ikkalasi ham almashtiriladi.
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureGotrueLocalStorage(),
        pkceAsyncStorage: SecureGotrueAsyncStorage(),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';

/// Supabase client'ini ishga tushirish uchun yupqa (thin) wrapper.
///
/// Bu klass faqat "qanday ulanish"ni biladi — qaysi jadvaldan nima o'qish
/// kerakligi haqida bilmaydi (bu `features/<nom>/data/datasources/`
/// mas'uliyati).
abstract final class SupabaseService {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

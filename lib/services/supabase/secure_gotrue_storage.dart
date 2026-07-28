import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../secure_storage/secure_storage_service.dart';

/// Supabase Auth sessiyasini (access/refresh token) `Flutter Secure
/// Storage` orqali saqlaydigan `LocalStorage` implementatsiyasi.
///
/// **Sabab:** `supabase_flutter`ning standart implementatsiyasi
/// (`SharedPreferencesLocalStorage`) tokenlarni oddiy, shifrlanmagan
/// `SharedPreferences`da saqlaydi — bu `docs/SECURITY.md`, "Autentifikatsiya"
/// bo'limidagi aniq taqiqni buzadi: "tokenlar Flutter Secure Storage orqali
/// saqlanadi — oddiy SharedPreferences'da saqlash taqiqlanadi." Bu klass
/// `services/supabase/supabase_client.dart`da `Supabase.initialize()`ga
/// `authOptions.localStorage` orqali uzatiladi.
class SecureGotrueLocalStorage extends LocalStorage {
  SecureGotrueLocalStorage({SecureStorageService? storageService})
    : _storageService =
          storageService ?? SecureStorageService(const FlutterSecureStorage());

  static const _sessionKey = 'adolat_ai_supabase_session';

  final SecureStorageService _storageService;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _storageService.read(key: _sessionKey) != null;
  }

  @override
  Future<String?> accessToken() {
    return _storageService.read(key: _sessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    return _storageService.delete(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storageService.write(
      key: _sessionKey,
      value: persistSessionString,
    );
  }
}

/// PKCE oqimida ishlatiladigan vaqtinchalik "code verifier"ni Flutter
/// Secure Storage orqali saqlaydi (masalan `resetPasswordForEmail`
/// ichida chaqiriladi — `GoTrueClient._generatePKCECodeChallenge()`).
/// Standart implementatsiya (`SharedPreferencesGotrueAsyncStorage`) shu
/// yerda ham oddiy `SharedPreferences`ga yozadi — [SecureGotrueLocalStorage]
/// bilan bir xil sababga ko'ra almashtiriladi.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({SecureStorageService? storageService})
    : _storageService =
          storageService ?? SecureStorageService(const FlutterSecureStorage());

  final SecureStorageService _storageService;

  @override
  Future<String?> getItem({required String key}) {
    return _storageService.read(key: key);
  }

  @override
  Future<void> removeItem({required String key}) {
    return _storageService.delete(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _storageService.write(key: key, value: value);
  }
}

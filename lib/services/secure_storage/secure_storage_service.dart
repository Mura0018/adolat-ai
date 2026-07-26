import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// `flutter_secure_storage` ustidan generik CRUD wrapper.
///
/// Feature'lar (masalan `features/auth/`) shu servisdan foydalanib token
/// saqlaydi/o'qiydi/o'chiradi — biznes qoidalari (masalan, "qachon o'chirish
/// kerak") bu klassda emas, chaqiruvchi feature qatlamida bo'ladi.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

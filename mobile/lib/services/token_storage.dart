import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT pair in OS-backed secure storage (Keychain / Keystore).
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'esda.access';
  static const _refreshKey = 'esda.refresh';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<String?> get access => _storage.read(key: _accessKey);

  Future<String?> get refresh => _storage.read(key: _refreshKey);

  Future<bool> get isAuthed async => (await access) != null;

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

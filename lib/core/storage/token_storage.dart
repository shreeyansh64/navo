import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _role = 'role';
  static const _email = 'email';

  final FlutterSecureStorage storage;
  TokenStorage({required this.storage});

  Future<String?> get accessToken => storage.read(key: _access);
  Future<String?> get refreshToken => storage.read(key: _refresh);
  Future<String?> get role => storage.read(key: _role);
  Future<String?> get email => storage.read(key: _email);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await storage.write(key: _access, value: access);
    await storage.write(key: _refresh, value: refresh);
  }

  Future<void> saveUser({String? role, String? email}) async {
    if (role != null) await storage.write(key: _role, value: role);
    if (email != null) await storage.write(key: _email, value: email);
  }

  /// Wipes the whole session, including any cached QR.
  Future<void> clear() => storage.deleteAll();
}

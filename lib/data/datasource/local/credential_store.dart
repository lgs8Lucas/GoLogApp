import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda token e senha do motorista criptografados (Android Keystore /
/// iOS Keychain) em vez do SQLite em texto puro. A senha é mantida para
/// refazer o login quando o token expira, já que o backend não oferece
/// refresh token.
class CredentialStore {
  static const _keyToken = 'auth_token';
  static const _keyPassword = 'auth_password';

  final FlutterSecureStorage _storage;

  CredentialStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  // Cache em memória: o token é lido a cada requisição.
  String? _token;
  bool _tokenLoaded = false;

  Future<String?> getToken() async {
    if (!_tokenLoaded) {
      _token = await _storage.read(key: _keyToken);
      _tokenLoaded = true;
    }
    return _token;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
    _token = token;
    _tokenLoaded = true;
  }

  Future<String?> getPassword() => _storage.read(key: _keyPassword);

  Future<void> savePassword(String password) =>
      _storage.write(key: _keyPassword, value: password);

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyPassword);
    _token = null;
    _tokenLoaded = true;
  }
}

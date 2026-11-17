import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:golog/data/datasource/remote/auth_api_service.dart';
import 'package:golog/data/model/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final AuthApi _authApi;
  final UserSqlService _userSqlService;
  final CredentialStore _credentials;

  AuthRepository(this._authApi, this._userSqlService, this._credentials);

  Future<User> login(
    String email,
    String password, {
    required bool keepConnected,
  }) async {
    final response = await _authApi.login(email, password);
    final data = ApiService.tryDecode(response.body);
    final map = data is Map ? data : const {};

    if (response.statusCode != 200) {
      final message = map['message'];
      throw AuthException(
        message is String && message.isNotEmpty
            ? message
            : _messageForStatus(response.statusCode),
      );
    }

    final token = map['token'];
    final userId = map['userId']?.toString() ?? '';
    if (token is! String || token.isEmpty || userId.isEmpty) {
      throw AuthException('Resposta inválida do servidor.');
    }

    final name = map['name'] ?? map['userName'];
    final user = User(
      id: userId,
      name: name is String && name.isNotEmpty ? name : 'Motorista',
      email: email,
      keepConnected: keepConnected,
    );
    await _credentials.saveToken(token);
    await _credentials.savePassword(password);
    await _userSqlService.replaceUser(user);
    return user;
  }

  Future<bool> hasValidSession() async {
    final user = await _userSqlService.getCurrentUser();
    if (user == null || !user.keepConnected) return false;
    final token = await _credentials.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _credentials.clear();
    await _userSqlService.deleteAllUsers();
  }

  static String _messageForStatus(int status) {
    if (status == 401 || status == 403) return 'E-mail ou senha inválidos.';
    if (status >= 500) return 'Servidor indisponível. Tente novamente.';
    return 'Falha na autenticação (código $status).';
  }
}

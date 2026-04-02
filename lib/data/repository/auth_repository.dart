import 'dart:convert';
import 'package:gologapp/data/datasource/remote/auth_api_service.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:get_storage/get_storage.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository(this._authApi);

  final _storage = GetStorage();

  Future<User> login(String email, String password) async {
    final response = await _authApi.login(email, password);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final String token = data['token'];
      await _storage.write('jwt_token', token);
      return User(id: "0", name: 'User Master', email: email);
    } else {
      throw Exception(data['message'] ?? 'Falha na autenticação');
    }
  }
}

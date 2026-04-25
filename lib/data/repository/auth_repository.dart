import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/datasource/remote/auth_api_service.dart';
import 'package:gologapp/data/model/user.dart';

class AuthRepository {
  final AuthApi _authApi;
  final UserSqlService _userSqlService = Get.find<UserSqlService>();
  final _storage = GetStorage();

  AuthRepository(this._authApi);

  Future<User> login(String email, String password) async {
    final response = await _authApi.login(email, password);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final String token = data['token'];
      await _storage.write('jwt_token', token);
      final user = User(
        id: "0",
        name: 'User Master',
        email: email,
        token: token,
        keepConnected: true,
      );
      await _userSqlService.deleteAllUsers();
      await _userSqlService.insertUser(user.toDb());
      return user;
    } else {
      throw Exception(data['message'] ?? 'Falha na autenticação');
    }
  }
}

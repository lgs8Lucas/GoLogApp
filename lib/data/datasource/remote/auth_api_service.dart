import 'package:http/http.dart' as http;
import 'package:gologapp/data/datasource/remote/api_service.dart';

class AuthApi {
  final ApiService _apiService;

  AuthApi(this._apiService);

  Future<http.Response> login(String email, String password) async {
    return await _apiService.post('/login', {
      'email': email,
      'password': password,
    });
  }
}

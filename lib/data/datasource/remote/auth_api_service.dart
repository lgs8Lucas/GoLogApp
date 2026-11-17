import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  final ApiService _apiService;

  AuthApi(this._apiService);

  Future<http.Response> login(String email, String password) =>
      _apiService.login(email, password);
}

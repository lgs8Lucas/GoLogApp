import 'dart:convert';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/util/connection_util.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final userSqlService = Get.find<UserSqlService>();
      final List<Map<String, dynamic>> users = await userSqlService
          .getAllUsers();
      if (users.isNotEmpty) {
        final userMap = users.first;
        final String? token = userMap['token'] ?? userMap[User.columnToken];

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      print('Erro ao buscar token no SQLite: $e');
    }

    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();
    var response = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 5));
    print('GET $endpoint - Status: ${response.statusCode}');
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    if (endpoint.contains("/login")) {
      return await http
          .post(
            url,
            body: jsonEncode(body),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
    } else {
      final headers = await _getHeaders();
      return await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));
    }
  }

  Future<http.Response> head(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    return await http
        .head(url, headers: headers)
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    return await http
        .delete(url, headers: headers)
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    return await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    return await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 5));
  }
}

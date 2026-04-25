import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl =
      'http://192.168.3.35:8081'; // 'http://10.0.2.2:8081' -> Para emulador Android // Subir Container Atualizado com tratamento de exceções

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .get(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> head(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .head(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .delete(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http
        .patch(
          url,
          headers: {'Content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
  }
}

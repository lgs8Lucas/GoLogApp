import 'dart:convert';
import 'package:gologapp/util/connection_util.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    return await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    return await http
        .get(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> head(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    return await http
        .head(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    return await http
        .delete(url, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 5));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
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
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    return await http
        .patch(
          url,
          headers: {'Content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
  }
}

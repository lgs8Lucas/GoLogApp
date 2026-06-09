import 'dart:convert';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/coordinate_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/model/coordinate.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/util/connection_util.dart';
import 'package:http/http.dart' as http;

class ApiService {
  bool isSyncing = false;

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

  Future<void> sync() async {
    if (isSyncing) return;
    isSyncing = true;

    try {
      // TODO: verificar se há conexão.
      await syncOccurrences();
      await syncCoords();
    } catch (e) {
      print('Erro durante a sincronização: $e');
    } finally {
      isSyncing = false;
    }
  }

  Future<void> syncOccurrences() async {
    try {
      final occurrenceSqlService = Get.find<OccurrenceSqlService>();
      final unsyncedOccurrences = await occurrenceSqlService
          .get('${Occurrence.columnIsSynced} = ?', [0]);

      for (final occurrence in unsyncedOccurrences) {
        print(occurrence.toJson());
        final response = await post('/occurrence', occurrence.toJson());
        if (response.statusCode == 200 || response.statusCode == 201) {
          await occurrenceSqlService.markAsSynced(occurrence);
        } else {
          print(
            'Falha ao sincronizar ocorrência: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Erro ao sincronizar ocorrências: $e');
    }
  }

  Future<void> syncCoords() async {
    try {
      final coordinateSqlService = Get.find<CoordinateSqlService>();
      final unsyncedCoordinates = await coordinateSqlService.get(
        '${Coordinate.columnIsSynced} = ?',
        [0],
      );

      for (final coordinate in unsyncedCoordinates) {
        final response = await post('/telemetry', coordinate.toJson());
        print(
          coordinate.toJson(),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          await coordinateSqlService.markAsSynced(coordinate);
        } else {
          print(
            'Falha ao sincronizar coordenada: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Erro ao sincronizar coordenadas: $e');
    }
  }
}

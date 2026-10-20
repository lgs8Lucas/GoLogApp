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

  // GET/HEAD/DELETE não carregam corpo, então tendem a ser rápidos. POST/PUT/
  // PATCH podem levar anexos (ex: a assinatura em SVG de uma ocorrência),
  // que em conexão móvel ruim facilmente passam de 5s — daí o timeout maior.
  static const Duration _readTimeout = Duration(seconds: 10);
  static const Duration _writeTimeout = Duration(seconds: 20);

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

  Future<http.Response> get(String endpoint, {bool allowRetry = true, Map<String, Object>? customParams}) async {
    var urlString = '${ConnectionUtil.gologApiUrl}$endpoint';
    if (customParams != null && customParams.isNotEmpty) {
      final queryParams = customParams.entries.map((entry) {
        return '${entry.key}=${entry.value}';
      }).join('&');
      urlString += '?$queryParams';
    }
    final url = Uri.parse(urlString);
    final headers = await _getHeaders();
    var response = await http.get(url, headers: headers).timeout(_readTimeout);
    print('GET $endpoint - Status: ${response.statusCode}');
    if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
      return get(endpoint, allowRetry: false);
    }
    return response;
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool allowRetry = true,
  }) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    if (endpoint.contains("/login")) {
      return await http
          .post(
            url,
            body: jsonEncode(body),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_writeTimeout);
    } else {
      final headers = await _getHeaders();
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_writeTimeout);
      if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
        return post(endpoint, body, allowRetry: false);
      }
      return response;
    }
  }

  Future<http.Response> head(String endpoint, {bool allowRetry = true}) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    final response = await http
        .head(url, headers: headers)
        .timeout(_readTimeout);
    if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
      return head(endpoint, allowRetry: false);
    }
    return response;
  }

  Future<http.Response> delete(String endpoint, {bool allowRetry = true}) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    final response = await http
        .delete(url, headers: headers)
        .timeout(_readTimeout);
    if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
      return delete(endpoint, allowRetry: false);
    }
    return response;
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool allowRetry = true,
  }) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    final response = await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(_writeTimeout);
    if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
      return put(endpoint, body, allowRetry: false);
    }
    return response;
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool allowRetry = true,
  }) async {
    final url = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    final headers = await _getHeaders();

    final response = await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(_writeTimeout);
    if (response.statusCode == 401 && allowRetry && await _refreshSession()) {
      return patch(endpoint, body, allowRetry: false);
    }
    return response;
  }

  // Refaz o login com as credenciais salvas localmente e atualiza o token
  // armazenado. Usado quando uma requisição autenticada retorna 401.
  Future<bool> _refreshSession() async {
    try {
      final userSqlService = Get.find<UserSqlService>();
      final users = await userSqlService.getAllUsers();
      if (users.isEmpty) return false;

      final userMap = users.first;
      final String email = userMap[User.columnEmail] ?? '';
      final String password = userMap[User.columnPassword] ?? '';
      if (email.isEmpty || password.isEmpty) return false;

      final response = await post('/login', {
        'email': email,
        'password': password,
      }, allowRetry: false);
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final String? token = data['token'];
      if (token == null || token.isEmpty) return false;

      await userSqlService.updateUser({
        User.columnId: userMap[User.columnId],
        User.columnToken: token,
      });
      return true;
    } catch (e) {
      print('Erro ao renovar sessão: $e');
      return false;
    }
  }

  Future<void> sync() async {
    if (isSyncing) return;
    isSyncing = true;

    try {
      // Tenta renovar o token proativamente antes de sincronizar, em vez de
      // só reagir a um 401 no meio do caminho — reduz a chance da primeira
      // requisição da sincronização falhar por token vencido. Se não
      // conseguir (ex: sem conexão), segue com o token atual mesmo assim;
      // cada chamada individual ainda tem seu próprio retry em caso de 401.
      await _refreshSession();
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
        try {
          print(occurrence.toJson());
          final response = await post('/occurrence', occurrence.toJson());
          if (response.statusCode == 200 || response.statusCode == 201) {
            await occurrenceSqlService.markAsSynced(occurrence);
          } else {
            print(
              'Falha ao sincronizar ocorrência: ${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          // Uma falha (ex: timeout) nesta ocorrência não deve impedir que
          // as demais pendentes sejam tentadas no mesmo ciclo — ela
          // continua isSynced=false e será retentada na próxima sync.
          print('Erro ao sincronizar ocorrência ${occurrence.localId}: $e');
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
        try {
          print(coordinate.toJson());
          final response = await post('/telemetry', coordinate.toJson());
          if (response.statusCode == 200 || response.statusCode == 201) {
            await coordinateSqlService.markAsSynced(coordinate);
          } else {
            print(
              'Falha ao sincronizar coordenada: ${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          // Mesmo raciocínio de syncOccurrences: isola a falha por item.
          print('Erro ao sincronizar coordenada: $e');
        }
      }
    } catch (e) {
      print('Erro ao sincronizar coordenadas: $e');
    }
  }
}

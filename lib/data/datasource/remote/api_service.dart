import 'dart:convert';

import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/util/connection_util.dart';
import 'package:golog/util/jwt_utils.dart';
import 'package:golog/util/log.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP da API GoLog: monta URL, injeta o token e, num 401,
/// refaz o login com as credenciais guardadas e repete a requisição uma vez.
class ApiService {
  // GET/HEAD/DELETE não carregam corpo, então tendem a ser rápidos. POST/PUT/
  // PATCH podem levar anexos (ex: a assinatura em SVG de uma ocorrência),
  // que em conexão móvel ruim facilmente passam de 5s — daí o timeout maior.
  static const Duration _readTimeout = Duration(seconds: 10);
  static const Duration _writeTimeout = Duration(seconds: 20);

  final CredentialStore _credentials;
  final UserSqlService _userSqlService;
  final http.Client _client;

  ApiService(this._credentials, this._userSqlService, [http.Client? client])
    : _client = client ?? http.Client();

  // Renovação em andamento: requisições que tomam 401 ao mesmo tempo
  // aguardam o mesmo login em vez de disparar um cada.
  Future<bool>? _refreshing;

  Uri _uri(String endpoint, [Map<String, Object?>? query]) {
    final base = Uri.parse('${ConnectionUtil.gologApiUrl}$endpoint');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        for (final e in query.entries)
          if (e.value != null) e.key: e.value.toString(),
      },
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _credentials.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, Object?>? query,
    bool auth = true,
    bool allowRetry = true,
  }) async {
    final request = http.Request(method, _uri(endpoint, query))
      ..headers.addAll(await _headers(auth: auth));
    if (body != null) request.body = jsonEncode(body);

    final timeout = body != null ? _writeTimeout : _readTimeout;
    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed).timeout(timeout);
    appLog('$method $endpoint -> ${response.statusCode}');

    if (response.statusCode == 401 &&
        auth &&
        allowRetry &&
        await refreshSession()) {
      return _send(
        method,
        endpoint,
        body: body,
        query: query,
        auth: auth,
        allowRetry: false,
      );
    }
    return response;
  }

  Future<http.Response> get(String endpoint, {Map<String, Object?>? query}) =>
      _send('GET', endpoint, query: query);

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) =>
      _send('POST', endpoint, body: body);

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) =>
      _send('PUT', endpoint, body: body);

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) =>
      _send('PATCH', endpoint, body: body);

  Future<http.Response> delete(String endpoint) => _send('DELETE', endpoint);

  /// Login sem token (não entra no fluxo de renovação).
  Future<http.Response> login(String email, String password) => _send(
    'POST',
    '/login',
    body: {'email': email, 'password': password},
    auth: false,
  );

  /// Renova o token se ele estiver para expirar. Evita que a primeira
  /// requisição de uma sincronização falhe com 401.
  Future<void> ensureFreshToken() async {
    final token = await _credentials.getToken();
    if (token == null || token.isEmpty) return;
    if (JwtUtils.isExpiringSoon(token)) await refreshSession();
  }

  /// Refaz o login com as credenciais salvas e atualiza o token.
  Future<bool> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final user = await _userSqlService.getCurrentUser();
      final password = await _credentials.getPassword();
      if (user == null || user.email.isEmpty) return false;
      if (password == null || password.isEmpty) return false;

      final response = await login(user.email, password);
      if (response.statusCode != 200) return false;

      final data = tryDecode(response.body);
      final token = data is Map ? data['token'] : null;
      if (token is! String || token.isEmpty) return false;

      await _credentials.saveToken(token);
      return true;
    } catch (e) {
      appLog('Erro ao renovar sessão: $e');
      return false;
    }
  }

  /// jsonDecode que devolve null em vez de lançar (ex: página HTML de um
  /// 502 do proxy).
  static dynamic tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

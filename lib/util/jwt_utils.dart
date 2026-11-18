import 'dart:convert';

class JwtUtils {
  /// Data de expiração (`exp`) de um JWT, ou null se o token não for um
  /// JWT legível ou não tiver `exp`. Não valida assinatura — só serve para
  /// decidir quando renovar a sessão.
  static DateTime? expiration(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      final exp = data is Map ? data['exp'] : null;
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// true quando o token expira em menos de [margin] (ou não dá para
  /// saber quando expira).
  static bool isExpiringSoon(
    String token, {
    Duration margin = const Duration(minutes: 5),
    DateTime? now,
  }) {
    final exp = expiration(token);
    if (exp == null) return true;
    return exp.isBefore((now ?? DateTime.now()).toUtc().add(margin));
  }
}

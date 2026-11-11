import 'package:gologapp/util/date_extensions.dart';

/// Helpers de exibição com fallback: qualquer dado vazio vindo do backend
/// ou do banco local vira um texto amigável em vez de string em branco,
/// "null" ou ", , , ," na tela.
class FormatUtils {
  static const String NOT_INFORMED = 'Não informado';

  static String orFallback(String? value, [String fallback = NOT_INFORMED]) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  /// "#001" a partir do código numérico; "---" quando ausente.
  static String routeCode(int? code) {
    if (code == null || code <= 0) return '#---';
    return '#${code.toString().padLeft(3, '0')}';
  }

  /// Remove partes vazias do endereço montado pelo model
  /// (ex: "Rua X, , São Paulo, , " -> "Rua X, São Paulo").
  static String address(String? raw) {
    final parts = (raw ?? '')
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Endereço não informado' : parts.join(', ');
  }

  static String dateTime(DateTime? date) =>
      date == null ? NOT_INFORMED : date.toDisplayFormat();
}

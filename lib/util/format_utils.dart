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

  /// "45 s", "12 min", "1 h 05 min" a partir de segundos.
  static String duration(double? seconds) {
    if (seconds == null || seconds < 0) return '--';
    final total = seconds.round();
    if (total < 60) return '$total s';
    final minutes = (total / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '$h h ${m.toString().padLeft(2, '0')} min';
  }

  /// "850 m" ou "3,4 km" a partir de metros.
  static String distance(double? meters) {
    if (meters == null || meters < 0) return '--';
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
  }

  /// Horário estimado de chegada ("14:32") somando os segundos restantes.
  static String arrivalTime(double? seconds, {DateTime? now}) {
    if (seconds == null || seconds < 0) return '--:--';
    final eta = (now ?? DateTime.now()).add(Duration(seconds: seconds.round()));
    return '${eta.hour.toString().padLeft(2, '0')}:'
        '${eta.minute.toString().padLeft(2, '0')}';
  }
}

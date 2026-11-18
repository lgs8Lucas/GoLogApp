/// Conversões tolerantes para dados vindos do backend/SQLite. O backend
/// pode mandar números como int, double ou string, e campos opcionais
/// como null — um cast direto (`as double`) derrubaria o parse do
/// registro inteiro.
class JsonParse {
  static double toDouble(Object? value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static int toInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static String toStr(Object? value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static DateTime? toDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? toMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

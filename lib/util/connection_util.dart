class ConnectionUtil {
  /// URL base da API. Configurável por build:
  ///   flutter run --dart-define=API_URL=https://api.exemplo.com.br
  /// O valor padrão é o servidor atual (ainda sem HTTPS).
  static const String gologApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://147.15.18.21:8081',
  );
}

import 'package:flutter/foundation.dart';

/// Log de diagnóstico. Só escreve em debug/profile: em release nada é
/// impresso, evitando vazar dados do motorista (token, localização,
/// assinatura) no logcat/console do aparelho.
void appLog(String message) {
  if (kReleaseMode) return;
  debugPrint(message);
}

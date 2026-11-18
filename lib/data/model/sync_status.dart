/// Situação do envio dos registros feitos no aparelho, para exibição.
class SyncStatus {
  final int pendingOccurrences;
  final int pendingCoordinates;
  final bool isSyncing;

  /// A última tentativa falhou por falta de conexão com o servidor.
  final bool offline;

  /// Quando a última sincronização terminou sem erro de rede.
  final DateTime? lastSuccessAt;

  const SyncStatus({
    this.pendingOccurrences = 0,
    this.pendingCoordinates = 0,
    this.isSyncing = false,
    this.offline = false,
    this.lastSuccessAt,
  });

  bool get hasPending => pendingOccurrences > 0 || pendingCoordinates > 0;

  SyncStatus copyWith({
    int? pendingOccurrences,
    int? pendingCoordinates,
    bool? isSyncing,
    bool? offline,
    DateTime? lastSuccessAt,
  }) {
    return SyncStatus(
      pendingOccurrences: pendingOccurrences ?? this.pendingOccurrences,
      pendingCoordinates: pendingCoordinates ?? this.pendingCoordinates,
      isSyncing: isSyncing ?? this.isSyncing,
      offline: offline ?? this.offline,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:golog/data/datasource/local/coordinate_sql_service.dart';
import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:golog/util/log.dart';

/// Resultado de uma sincronização.
enum SyncResult {
  /// Terminou (itens rejeitados pelo servidor continuam pendentes).
  done,

  /// Interrompida por falta de conexão com o servidor.
  offline,

  /// Ninguém logado: nada foi enviado.
  skipped,
}

/// Envia ao servidor o que foi registrado offline (ocorrências e
/// telemetria) e limpa do aparelho o trajeto já enviado há algum tempo.
/// (A limpeza de ocorrências fica no RouteRepository, que conhece a lista
/// atual do servidor.)
class SyncRepository {
  /// Máximo de coordenadas enviadas por ciclo, para um ciclo não ficar
  /// rodando indefinidamente depois de muito tempo offline.
  static const int _maxCoordinatesPerCycle = 500;
  static const Duration _keepSyncedCoordinates = Duration(days: 2);

  final ApiService _api;
  final CredentialStore _credentials;
  final OccurrenceSqlService _occurrences;
  final CoordinateSqlService _coordinates;

  /// Chamado sempre que um item é enviado (para atualizar contadores).
  void Function()? onProgress;

  SyncRepository(
    this._api,
    this._credentials,
    this._occurrences,
    this._coordinates,
  );

  Future<SyncResult>? _running;
  bool _rerunRequested = false;

  bool get isRunning => _running != null;

  /// Executa uma sincronização. Se já houver uma em andamento, ela é
  /// repetida assim que terminar — assim um registro criado no meio do
  /// envio (depois que a lista de pendentes já foi lida) não precisa
  /// esperar o próximo ciclo.
  Future<SyncResult> sync() {
    final running = _running;
    if (running != null) {
      _rerunRequested = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<SyncResult> _loop() async {
    SyncResult result;
    do {
      _rerunRequested = false;
      result = await _sync();
    } while (_rerunRequested && result == SyncResult.done);
    return result;
  }

  Future<int> pendingOccurrences() => _occurrences.countUnsynced();
  Future<int> pendingCoordinates() => _coordinates.countUnsynced();

  Future<SyncResult> _sync() async {
    final token = await _credentials.getToken();
    if (token == null || token.isEmpty) return SyncResult.skipped;

    try {
      await _api.ensureFreshToken();
      await _syncOccurrences();
      await _syncCoordinates();
      await _coordinates.purgeSynced(_keepSyncedCoordinates);
      return SyncResult.done;
    } catch (e) {
      appLog('Erro durante a sincronização: $e');
      return _isNetworkError(e) ? SyncResult.offline : SyncResult.done;
    }
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException || e is TimeoutException || e is HttpException;

  Future<void> _syncOccurrences() async {
    for (final occurrence in await _occurrences.getUnsynced()) {
      try {
        final response = await _api.post('/occurrence', occurrence.toJson());
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _occurrences.markAsSynced(occurrence);
          onProgress?.call();
        } else {
          // Erro do servidor para este item: segue para os próximos; ele
          // continua pendente e é retentado no próximo ciclo.
          appLog(
            'Falha ao sincronizar ocorrência ${occurrence.localId}: '
            '${response.statusCode}',
          );
        }
      } catch (e) {
        appLog('Erro ao sincronizar ocorrência ${occurrence.localId}: $e');
        // Sem rede: os próximos também falhariam (cada um esperando o
        // timeout). Encerra o ciclo e tenta de novo no próximo.
        if (_isNetworkError(e)) rethrow;
      }
    }
  }

  Future<void> _syncCoordinates() async {
    final pending = await _coordinates.getUnsynced(
      limit: _maxCoordinatesPerCycle,
    );
    for (var i = 0; i < pending.length; i++) {
      // Uma ocorrência nova tem prioridade sobre o trajeto: interrompe e
      // deixa o _loop recomeçar pelas ocorrências.
      if (_rerunRequested) return;
      final coordinate = pending[i];
      try {
        final response = await _api.post('/telemetry', coordinate.toJson());
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _coordinates.markAsSynced(coordinate);
          // Contador do trajeto não precisa ser exato a cada ponto.
          if (i % 25 == 0) onProgress?.call();
        } else {
          appLog('Falha ao sincronizar coordenada: ${response.statusCode}');
        }
      } catch (e) {
        appLog('Erro ao sincronizar coordenada: $e');
        if (_isNetworkError(e)) rethrow;
      }
    }
  }
}

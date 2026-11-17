import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:golog/data/model/sync_status.dart';
import 'package:golog/data/repository/sync_repository.dart';
import 'package:golog/util/log.dart';

export 'package:golog/data/model/sync_status.dart';

class SyncController extends GetxController with WidgetsBindingObserver {
  /// Ciclo de fundo: pega o que ficou para trás (ex: registros feitos
  /// offline) e o trajeto, que não dispara envio a cada ponto.
  static const Duration _interval = Duration(minutes: 3);

  final SyncRepository _syncRepository;
  Timer? _syncTimer;

  final status = const SyncStatus().obs;

  SyncController(this._syncRepository);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _syncRepository.onProgress = refreshCounts;
    syncNow();
    _syncTimer = Timer.periodic(_interval, (_) => syncNow());
  }

  /// Dispara uma sincronização (sem efeito se não houver usuário logado).
  Future<void> syncNow() async {
    status.value = status.value.copyWith(isSyncing: true);
    try {
      final result = await _syncRepository.sync();
      status.value = status.value.copyWith(
        offline: result == SyncResult.offline,
        lastSuccessAt: result == SyncResult.done ? DateTime.now() : null,
      );
    } catch (e) {
      appLog('SyncController: erro inesperado: $e');
    } finally {
      if (!_syncRepository.isRunning) {
        status.value = status.value.copyWith(isSyncing: false);
      }
      await refreshCounts();
    }
  }

  /// Avisa que um registro novo foi salvo: atualiza o contador na hora e
  /// tenta enviar imediatamente.
  void notifyNewRecord() {
    refreshCounts();
    syncNow();
  }

  Future<void> refreshCounts() async {
    try {
      status.value = status.value.copyWith(
        pendingOccurrences: await _syncRepository.pendingOccurrences(),
        pendingCoordinates: await _syncRepository.pendingCoordinates(),
      );
    } catch (e) {
      appLog('SyncController: erro ao contar pendências: $e');
    }
  }

  // Ao voltar de background não vale esperar até 3 minutos: o motorista
  // pode ter acabado de recuperar a conexão.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncNow();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _syncRepository.onProgress = null;
    super.onClose();
  }
}

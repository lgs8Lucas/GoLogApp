import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/remote/api_service.dart';

class SyncController extends GetxController with WidgetsBindingObserver {
  final ApiService _apiService = Get.find<ApiService>();
  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    // Executa a primeira sincronização imediatamente ao iniciar
    _apiService.sync();

    // Configura o timer para rodar a cada 3 minutos
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      print('SyncController: Iniciando sincronização programada...');
      _apiService.sync();
    });
  }

  // Dispara uma sincronização também quando o app volta de background —
  // não vale a pena esperar até 3 minutos se o usuário acabou de reabrir
  // o app depois de ter ficado offline ou minimizado por um tempo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('SyncController: App retomado, sincronizando...');
      _apiService.sync();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.onClose();
  }
}

import 'dart:async';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/remote/api_service.dart';

class SyncController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();
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

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
}

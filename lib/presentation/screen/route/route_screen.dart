import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golog/presentation/controller/location_controller.dart';
import 'package:golog/presentation/controller/login_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/controller/sync_controller.dart';
import 'package:golog/presentation/screen/route/route_view.dart';

/// Liga [RouteController]/[LoginController] ao layout puro [RouteListView].
///
/// É a primeira tela depois do login (ou da sessão restaurada): é aqui que
/// as rotas são carregadas e o GPS começa a ser acompanhado.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final LoginController loginController = Get.find<LoginController>();
  final RouteController routeController = Get.find<RouteController>();
  final SyncController syncController = Get.find<SyncController>();

  @override
  void initState() {
    super.initState();
    routeController.fetchTransports();
    Get.find<LocationController>().start();
    syncController.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RouteListView(
        transports: routeController.transportList.toList(),
        isLoading: routeController.isLoading.value,
        errorMessage: routeController.errorMessage.value,
        onDismissError: routeController.clearError,
        onRefresh: routeController.fetchTransports,
        onTapTransport: routeController.goToDetails,
        onLogout: loginController.logout,
        syncStatus: syncController.status.value,
        onSyncNow: syncController.syncNow,
      ),
    );
  }
}

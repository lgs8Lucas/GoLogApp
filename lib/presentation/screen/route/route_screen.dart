import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/login_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/presentation/screen/route/route_view.dart';

/// Liga [RouteController]/[LoginController] ao layout puro [RouteListView].
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final RouteController routeController = Get.find<RouteController>();

    return Obx(
      () => RouteListView(
        transports: routeController.transportList.toList(),
        isLoading: routeController.isLoading.value,
        errorMessage: routeController.errorMessage.value,
        onDismissError: routeController.clearError,
        onRefresh: routeController.fetchTransports,
        onTapTransport: routeController.goToDetails,
        onLogout: loginController.logout,
      ),
    );
  }
}

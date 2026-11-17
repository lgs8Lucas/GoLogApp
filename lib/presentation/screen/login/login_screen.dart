import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golog/presentation/controller/login_controller.dart';
import 'package:golog/presentation/screen/login/login_view.dart';

/// Liga o [LoginController] ao layout puro [LoginView].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return Obx(
      () => LoginView(
        emailController: controller.emailController,
        passwordController: controller.passwordController,
        obscurePassword: controller.obscurePassword.value,
        keepConnected: controller.keepConnected.value,
        isLoading: controller.isLoading.value,
        onTogglePassword: controller.togglePasswordVisibility,
        onToggleKeepConnected: controller.toggleKeepConnected,
        onSubmit: () {
          // Evita disparar dois logins com toques repetidos.
          if (!controller.isLoading.value) controller.login();
        },
      ),
    );
  }
}

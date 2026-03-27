import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var obscurePassword = true.obs;
  var keepConnected = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleKeepConnected(bool? value) {
    keepConnected.value = value ?? false;
  }

  void login() {
    Get.toNamed('/route_screen');
  }
}

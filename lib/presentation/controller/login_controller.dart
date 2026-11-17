import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golog/data/repository/auth_repository.dart';
import 'package:golog/data/repository/route_repository.dart';
import 'package:golog/presentation/controller/location_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/controller/sync_controller.dart';
import 'package:golog/util/log.dart';
import 'package:golog/util/styles.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var keepConnected = true.obs;

  final AuthRepository _authRepository;
  final RouteRepository _routeRepository;
  final RouteController _routeController;
  final LocationController _locationController;
  final SyncController _syncController;

  LoginController(
    this._authRepository,
    this._routeRepository,
    this._routeController,
    this._locationController,
    this._syncController,
  );

  void togglePasswordVisibility() => obscurePassword.toggle();
  void toggleKeepConnected(bool? value) => keepConnected.value = value ?? false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Campo vazio', 'Por favor preencha todos os campos');
      return;
    }

    try {
      isLoading.value = true;
      final user = await _authRepository.login(
        email,
        password,
        keepConnected: keepConnected.value,
      );
      passwordController.clear();
      _showSuccessSnackbar('Sucesso', 'Bem-vindo ao GoLog, ${user.name}!');
      Get.offAllNamed('/route_screen');
    } catch (e) {
      _showErrorSnackbar('Falha no Login', _loginErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  static String _loginErrorMessage(Object e) {
    if (e is AuthException) return e.message;
    if (e is SocketException || e is TimeoutException) {
      return 'Sem conexão com o servidor. Verifique a internet.';
    }
    appLog('Erro inesperado no login: $e');
    return 'Não foi possível entrar. Tente novamente.';
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Styles.COLOR_WHITE,
      colorText: Styles.COLOR_RED,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.error, color: Styles.COLOR_RED),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Styles.COLOR_WHITE,
      colorText: Colors.green,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.check, color: Colors.green),
    );
  }

  Future<String> initialRoute() async =>
      await _authRepository.hasValidSession() ? '/route_screen' : '/login';

  Future<void> logout() async {
    await Get.showOverlay(
      asyncFunction: () async {
        // Última tentativa de enviar o que está pendente enquanto o token
        // ainda existe. O que não for enviado continua salvo no aparelho
        // e sobe no próximo login.
        try {
          await _syncController.syncNow().timeout(const Duration(seconds: 15));
        } catch (_) {}
        _locationController.stop();
        await _authRepository.logout();
        await _routeRepository.clearCache();
        _routeController.reset();
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
    // LoginController é permanente: sem isso, as credenciais do motorista
    // anterior continuariam preenchidas para o próximo.
    emailController.clear();
    passwordController.clear();
    obscurePassword.value = true;
    Get.offAllNamed('/login');
  }
}

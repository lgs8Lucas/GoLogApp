import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/data/repository/auth_repository.dart';
import 'package:gologapp/util/styles.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var keepConnected = true.obs;

  final AuthRepository _authRepository;
  final UserSqlService _userSqlService;
  LoginController(this._authRepository, this._userSqlService);

  void togglePasswordVisibility() => obscurePassword.toggle();
  void toggleKeepConnected(bool? value) => keepConnected.value = value ?? false;

  Future<void> login() async {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Campo vazio', 'Por favor preencha todos os campos');
      return;
    }

    try {
      isLoading.value = true;
      final user = await _authRepository.login(email, password);

      _showSuccessSnackbar('Sucesso', 'Bem-vindo ao GoLogApp, ${user.name}!');
      Get.offAllNamed('/route_screen');
    } catch (e) {
      _showErrorSnackbar(
        'Falha no Login',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String title, String message) {
    try {
      Get.snackbar(
        title,
        message,
        backgroundColor: Styles.COLOR_WHITE,
        colorText: Styles.COLOR_RED,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Styles.COLOR_RED),
      );
    } catch (e) {
      print('Erro ao mostrar snackbar: $e');
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    try {
      Get.snackbar(
        title,
        message,
        backgroundColor: Styles.COLOR_WHITE,
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.check, color: Colors.green),
      );
    } catch (e) {
      print('Erro ao mostrar snackbar: $e');
    }
  }

  Future<String> tryKeepConnected() async {
    final user = (await _userSqlService.getAllUsers()).firstOrNull;
    if (user == null || user[User.columnKeepConnected] != 1) return '/login';
    final email = user[User.columnEmail] ?? '';
    final password = user[User.columnPassword] ?? '';

    if (email.isEmpty || password.isEmpty) {
      return '/login';
    }

    try {
      isLoading.value = true;
      await _authRepository.login(email, password);
      return '/route_screen';
    } catch (e) {
      // Verificar se a tela está montada para exibir o erro
      if (Get.isPrepared()) {
        _showErrorSnackbar(
          'Falho no Login',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
      return '/login';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _userSqlService.deleteAllUsers();
    Get.offAllNamed('/login');
  }
}

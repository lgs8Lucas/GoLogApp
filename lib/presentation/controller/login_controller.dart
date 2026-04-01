import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:gologapp/util/styles.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var keepConnected = true.obs;

  final String _baseUrl =
      'http://localhost:8080/login'; // 'http://10.0.2.2:8081/login' -> Para emulador Android, 'http://localhost:8081/login' -> Para Linux

  void togglePasswordVisibility() => obscurePassword.toggle();

  void toggleKeepConnected(bool? value) => keepConnected.value = value ?? false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Campo Vazio',
        'Por favor, preencha todos os campos',
        backgroundColor: Styles.COLOR_WHITE,
        colorText: Styles.COLOR_RED,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];
        String mensagemDeErro = 'Erro desconhecido';

        Get.snackbar(
          'Sucesso',
          'Bem vindo ao GoLog!',
          backgroundColor: Styles.COLOR_WHITE,
          colorText: Colors.green,
        );
        Get.offNamed('/route_screen');
      } else {
        String mensagemDeErro = 'Erro desconhecido';

        try {
          final errorData = jsonDecode(response.body);
          mensagemDeErro = errorData['message'] ?? 'Falha na autenticação';
        } catch (e) {
          mensagemDeErro = 'Erro no servidor: ${response.statusCode}';
        }
        Get.snackbar(
          'Falha no Login',
          mensagemDeErro,
          backgroundColor: Styles.COLOR_WHITE,
          colorText: Styles.COLOR_RED,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro de Conexão',
        'Verifique se o backend está rodando no Docker.',
      );
      print("Erro detalhado: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

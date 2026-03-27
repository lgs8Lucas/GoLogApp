import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/login_controller.dart';
import 'package:gologapp/util/styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Injetando o controller na memória
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Styles.COLOR_BLACKBLUE,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TODO: Image.asset('assets/images/logo_golog.png', height: 60),
                      const Icon(Icons.location_on_outlined, 
                          color: Styles.COLOR_LIGHTGREEN, size: 50),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: 'Go', style: TextStyle(color: Styles.COLOR_LIGHTGREEN)),
                            TextSpan(text: 'Log', style: TextStyle(color: Styles.COLOR_WHITE)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- AVATAR ---
            Container(
              width: 120, height: 120,
              decoration: const BoxDecoration(color: Styles.COLOR_BLACKBLUE, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, size: 80, color: Styles.COLOR_WHITE),
            ),

            const SizedBox(height: 40),

            // --- FORMULÁRIO ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Exemplo@gmail.com',
                      filled: true,
                      fillColor: Styles.COLOR_WHITE,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Senha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  // --- CAMPO DE SENHA REATIVO ---
                  Obx(() => TextFormField(
                    obscureText: controller.obscurePassword.value,
                    decoration: InputDecoration(
                      hintText: '****',
                      filled: true,
                      fillColor: Styles.COLOR_WHITE,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  )),

                  const SizedBox(height: 12),

                  // --- CHECKBOX REATIVO ---
                  Row(
                    children: [
                      Obx(() => Checkbox(
                        value: controller.keepConnected.value,
                        activeColor: Styles.COLOR_BLACK,
                        onChanged: controller.toggleKeepConnected,
                      )),
                      const Text('Manter conectado.'),
                    ],
                  ),

                  const SizedBox(height: 40),

                  
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.toNamed('/route_screen'); // Navega para a tela de rotas
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.COLOR_GRAY,
                        foregroundColor: Styles.COLOR_WHITE,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
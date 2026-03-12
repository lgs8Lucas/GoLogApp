import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/screens/login_screen.dart'; // Ajuste o path
import 'package:gologapp/util/styles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GoLog',
      theme: ThemeData(scaffoldBackgroundColor: Styles.COLOR_WHITE),
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        /*
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
          binding: HomeBinding(), // Se usar injeção de dependência organizada
        ),
        */
      ],
    );
  }
}

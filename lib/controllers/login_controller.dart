import 'package:get/get.dart';

class LoginController extends GetxController {
  var obscurePassword = true.obs;
  var keepConnected = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleKeepConnected(bool? value) {
    keepConnected.value = value ?? false;
  }
}

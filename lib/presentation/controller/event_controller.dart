import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/screen/events/event_page.dart';

class OccurrenceActionController extends GetxController {
  var currentAction = ActionType.signature.obs;
  final observationTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is ActionType) {
      currentAction.value = Get.arguments;
    }
  }

  @override
  void onClose() {
    observationTextController.dispose();
    super.onClose();
  }
}

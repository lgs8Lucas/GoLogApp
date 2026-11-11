import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/occurrence_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/presentation/screen/events/occurrence_view.dart';
import 'package:gologapp/util/format_utils.dart';

/// Liga o [OccurrenceController] ao layout puro [OccurrenceView].
class OccurrenceScreen extends StatelessWidget {
  final controller = Get.find<OccurrenceController>();
  final routeController = Get.find<RouteController>();

  OccurrenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final delivery = routeController.selectedDelivery;
    final String? stopLabel = delivery == null
        ? null
        : '${delivery.isPickup ? 'Coleta' : 'Entrega'} ${FormatUtils.routeCode(delivery.deliverySequence)}';

    return Obx(
      () => OccurrenceView(
        action: controller.currentAction.value,
        // Antes o cabeçalho mostrava "Rota #001" fixo.
        routeCode: routeController.selectedTransport?.codeTransport,
        stopLabel: stopLabel,
        signatureController: controller.signatureController,
        observationController: controller.observationTextController,
        isSaving: controller.isSaving.value,
        onBack: () => Get.back(),
        onSubmit: controller.saveOccurrence,
      ),
    );
  }
}

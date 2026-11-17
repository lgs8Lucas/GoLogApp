import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:golog/presentation/controller/occurrence_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/screen/events/occurrence_view.dart';
import 'package:golog/util/format_utils.dart';

/// Liga o [OccurrenceController] ao layout puro [OccurrenceView].
///
/// A assinatura é coletada com o aparelho deitado (paisagem): mais largura
/// para assinar e a linha fica na horizontal. As demais ações seguem em
/// retrato, como o resto do app.
class OccurrenceScreen extends StatefulWidget {
  const OccurrenceScreen({super.key});

  @override
  State<OccurrenceScreen> createState() => _OccurrenceScreenState();
}

class _OccurrenceScreenState extends State<OccurrenceScreen> {
  final controller = Get.find<OccurrenceController>();
  final routeController = Get.find<RouteController>();

  late final bool _isSignature =
      controller.currentAction.value == ActionType.signature;

  @override
  void initState() {
    super.initState();
    if (_isSignature) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    if (_isSignature) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    }
    super.dispose();
  }

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

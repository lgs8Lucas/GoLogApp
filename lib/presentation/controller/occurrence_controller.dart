import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/delivery_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:signature/signature.dart';

enum ActionType { signature, observation, finish }

class OccurrenceController extends GetxController {
  final RouteController _routeController = Get.find<RouteController>();
  final OccurrenceSqlService _occurrenceSqlService =
      Get.find<OccurrenceSqlService>();
  final UserSqlService _userSqlService = Get.find<UserSqlService>();
  final DeliverySqlService _deliverySqlService = Get.find<DeliverySqlService>();

  var currentAction = ActionType.signature.obs;
  final observationTextController = TextEditingController();
  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void onClose() {
    observationTextController.dispose();
    signatureController.dispose();
    super.onClose();
  }

  Future<void> saveOccurrence() async {
    final delivery = _routeController.selectedDelivery;
    final transport = _routeController.selectedTransport;

    if (delivery == null || transport == null) return;

    final users = await _userSqlService.getAllUsers();
    final senderId = users.isNotEmpty
        ? (users.first[User.columnId]?.toString() ?? '')
        : '';

    String type = currentAction.value == ActionType.signature || currentAction.value == ActionType.finish
        ? OccurrenceType.Fim.name
        : OccurrenceType.Parada.name;
    String description = currentAction.value == ActionType.signature
        ? "Entrega finalizada com sucesso"
        : observationTextController.text;

    String attachment = "";
    if (currentAction.value == ActionType.signature &&
        signatureController.isNotEmpty) {
      final svg = signatureController.toRawSVG();
      attachment = svg ?? "";
    }

    final occurrence = Occurrence(
      type: type,
      description: description,
      attachment: attachment,
      deliveryId: delivery.id,
      transportId: transport.id,
      senderId: senderId,
      isSynced: false,
      dateTime: DateTime.now(),
    );

    await _occurrenceSqlService.insertOccurrence(occurrence);
    if (currentAction.value == ActionType.signature) {
      delivery.status = "Finalizado";
      await _deliverySqlService.updateDelivery(
        {Delivery.columnStatus: "Finalizado"},
        '${Delivery.columnId} = ? AND ${Delivery.columnTransportId} = ?',
        [delivery.id, transport.id],
      );
      _routeController.transportList.refresh();
    }

    observationTextController.clear();
    Get.back();
    if (currentAction.value == ActionType.signature ||
        currentAction.value == ActionType.finish) {
      Get.back();
    }
  }
}

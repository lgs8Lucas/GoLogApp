import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/delivery_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';

enum ActionType { signature, observation }

class OccurrenceController extends GetxController {
  final RouteController _routeController = Get.find<RouteController>();
  final OccurrenceSqlService _occurrenceSqlService = Get.find<OccurrenceSqlService>();
  final UserSqlService _userSqlService = Get.find<UserSqlService>();
  final DeliverySqlService _deliverySqlService = Get.find<DeliverySqlService>();

  var currentAction = ActionType.signature.obs; 
  final observationTextController = TextEditingController();

  @override
  void onClose() {
    observationTextController.dispose();
    super.onClose();
  }

  Future<void> saveOccurrence() async {
    final delivery = _routeController.selectedDelivery;
    final transport = _routeController.selectedTransport;

    if (delivery == null || transport == null) return;

    final users = await _userSqlService.getAllUsers();
    final senderId = users.isNotEmpty ? (users.first[User.columnId]?.toString() ?? '') : '';

    String type = currentAction.value == ActionType.signature ? OccurrenceType.Fim.name : OccurrenceType.Parada.name;
    String description = currentAction.value == ActionType.signature 
        ? "Entrega finalizada com sucesso" 
        : observationTextController.text;

    final occurrence = Occurrence(
      type: type,
      description: description,
      attachment: "", // Aqui entrará a lógica de salvar a imagem da assinatura/foto futuramente
      deliveryId: delivery.id,
      transportId: transport.id,
      senderId: senderId,
      isSynced: false,
      dateTime: DateTime.now(),
    );

    await _occurrenceSqlService.insertOccurrence(occurrence);

    if (currentAction.value == ActionType.signature) {
      await _deliverySqlService.updateDelivery({Delivery.columnStatus: "Finalizado"}, '${Delivery.columnId} = ? AND ${Delivery.columnTransportId} = ?', [delivery.id, transport.id]);
    }

    observationTextController.clear();
    Get.back();
  }
}
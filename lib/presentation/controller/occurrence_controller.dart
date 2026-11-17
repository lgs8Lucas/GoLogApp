import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golog/data/datasource/local/delivery_sql_service.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/model/action_type.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/controller/sync_controller.dart';
import 'package:golog/util/log.dart';
import 'package:golog/util/styles.dart';
import 'package:signature/signature.dart';

export 'package:golog/data/model/action_type.dart';

class OccurrenceController extends GetxController {
  final RouteController _routeController;
  final OccurrenceSqlService _occurrenceSqlService;
  final UserSqlService _userSqlService;
  final DeliverySqlService _deliverySqlService;
  final SyncController _syncController;

  OccurrenceController(
    this._routeController,
    this._occurrenceSqlService,
    this._userSqlService,
    this._deliverySqlService,
    this._syncController,
  );

  var currentAction = ActionType.signature.obs;
  // Trava o botão enquanto salva: evita ocorrências duplicadas por toque
  // duplo no botão de confirmar.
  var isSaving = false.obs;
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

  // Ponto de entrada de toda nova ocorrência. O controller é um singleton
  // reaproveitado por todas as entregas, então o estado transiente (traço
  // da assinatura, texto de observação) precisa ser limpo aqui — se só
  // limpar ao salvar, uma assinatura feita e não descartada corretamente
  // (ou um texto digitado e abandonado) continua aparecendo na próxima
  // entrega.
  void startNewOccurrence(ActionType action) {
    currentAction.value = action;
    signatureController.clear();
    observationTextController.clear();
  }

  // Verifica se já existe uma ocorrência de desfecho (entregue ou não) para
  // essa entrega. Ignora as ocorrências automáticas de Início/Continuando
  // criadas ao iniciar a entrega — só Fim (entregue) ou Parada (ocorrência
  // registrada) contam como um desfecho válido para liberar a saída da tela.
  Future<bool> hasOutcomeOccurrence(String deliveryId) async {
    final occurrences = await _occurrenceSqlService.get(
      '${Occurrence.columnDeliveryId} = ? AND ${Occurrence.columnType} IN (?, ?)',
      [deliveryId, OccurrenceType.Fim.name, OccurrenceType.Parada.name],
    );
    return occurrences.isNotEmpty;
  }

  Future<void> saveOccurrence() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await _saveOccurrence();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveOccurrence() async {
    final delivery = _routeController.selectedDelivery;
    final transport = _routeController.selectedTransport;
    if (delivery == null || transport == null) return;

    final action = currentAction.value;
    final finishesDelivery =
        action == ActionType.signature || action == ActionType.finish;

    final senderId = await _userSqlService.getCurrentUserId();

    String attachment = '';
    if (action == ActionType.signature && signatureController.isNotEmpty) {
      attachment = signatureController.toRawSVG() ?? '';
    }

    final occurrence = Occurrence(
      type: finishesDelivery
          ? OccurrenceType.Fim.name
          : OccurrenceType.Parada.name,
      description: action == ActionType.signature
          ? 'Entrega finalizada com sucesso'
          : observationTextController.text.trim(),
      attachment: attachment,
      deliveryId: delivery.id,
      transportId: transport.id,
      senderId: senderId,
      isSynced: false,
      dateTime: DateTime.now(),
    );

    try {
      await _occurrenceSqlService.insertOccurrence(occurrence);
      if (finishesDelivery) {
        await _deliverySqlService.updateStatus(
          delivery,
          DeliveryStatus.finished,
        );
        delivery.status = DeliveryStatus.finished;
      }
    } catch (e) {
      appLog('Erro ao salvar ocorrência: $e');
      Get.snackbar(
        'Erro ao salvar',
        'Não foi possível registrar a ocorrência. Tente novamente.',
        backgroundColor: Styles.COLOR_WHITE,
        colorText: Styles.COLOR_RED,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Tenta enviar na hora; sem conexão, fica pendente para o próximo ciclo.
    _syncController.notifyNewRecord();

    if (action == ActionType.finish) {
      // "Finalizar rota": encerra a parada atual e para de gravar o trajeto.
      _routeController.transportList.refresh();
      _routeController.stopTracking();
    } else if (finishesDelivery) {
      _routeController.onDeliveryFinished();
    }

    observationTextController.clear();
    Get.back(); // fecha a tela de ocorrência
    if (finishesDelivery) Get.back(); // sai da parada
  }
}

import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/delivery_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/sql_service.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/datasource/local/transport_sql_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/data/repository/route_repository.dart';

class RouteController extends GetxController {
  final TransportSqlService _transportSqlService =
      Get.find<TransportSqlService>();
  final RouteRepository _routeRepository = Get.find<RouteRepository>();
  final OccurrenceSqlService _occurrenceSqlService =
      Get.find<OccurrenceSqlService>();
  final UserSqlService _userSqlService = Get.find<UserSqlService>();
  final DeliverySqlService _deliverySqlService = Get.find<DeliverySqlService>();
  final SqlService _sqlService = Get.find<SqlService>();

  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var transportList = <Transport>[].obs;
  Transport? selectedTransport;
  Delivery? selectedDelivery;
  bool inProgress = false;

  @override
  void onInit() {
    super.onInit();
    fetchTransports();
  }

  Future<void> fetchTransports() async {
    try {
      isLoading(true);
      var data = await _routeRepository.getTransports();
      data.sort((a, b) => a.codeTransport.compareTo(b.codeTransport));
      transportList.assignAll(data);
    } catch (e) {
      print('Erro ao buscar transportes: $e');
      errorMessage.value = 'Erro ao buscar transportes: $e';
    } finally {
      isLoading(false);
    }
  }

  void goToDetails(Transport transport) {
    selectedTransport = transport;
    Get.toNamed('/route_details');
  }

  void goToDeliveryRoute(Delivery delivery) {
    selectedDelivery = delivery;
    Get.toNamed('/delivery_route');
  }

  void clearError() {
    errorMessage.value = '';
  }

  Future<void> startRoute() async {
    if (selectedTransport == null) return;
    for (var delivery in Delivery.sortedBySequence(
      selectedTransport!.deliveries,
    )) {
      if (delivery.status != "Finalizado") {
        await startDelivery(delivery);
        break; // Inicia apenas a primeira entrega pendente na sequência
      }
    }
  }

  Future<void> startDelivery(Delivery delivery) async {
    if (delivery.status == "Finalizado") return;

    final users = await _userSqlService.getAllUsers();
    final senderId = users.isNotEmpty
        ? (users.first[User.columnId]?.toString() ?? '')
        : '';

    try {
      if (delivery.status != "Iniciado") {
        await _sqlService.db.transaction((txn) async {
          // É vital passar o 'txn' para que as operações façam parte da mesma transação
          await _occurrenceSqlService.insertOccurrence(
            Occurrence(
              type: OccurrenceType.Inicio.name,
              description: "Início da rota",
              attachment: "",
              deliveryId: delivery.id,
              transportId: selectedTransport!.id,
              senderId: senderId,
              isSynced: false,
              dateTime: DateTime.now(),
            ),
            txn: txn,
          );
          delivery.status = "Iniciado";
          await _deliverySqlService.updateDelivery(
            {Delivery.columnStatus: "Iniciado"},
            '${Delivery.columnId} = ? AND ${Delivery.columnTransportId} = ?',
            [delivery.id, selectedTransport!.id],
            txn: txn,
          );
        });
      } else {
        await _occurrenceSqlService.insertOccurrence(
          Occurrence(
            type: OccurrenceType.Continuando.name,
            description: "Continuação da rota",
            attachment: "",
            deliveryId: delivery.id,
            transportId: selectedTransport!.id,
            senderId: senderId,
            isSynced: false,
            dateTime: DateTime.now(),
          ),
        );
      }

      // Só atualiza o estado da UI e navega se o banco de dados foi atualizado com sucesso
      selectedDelivery = delivery;
      inProgress = true;
      Get.toNamed('/delivery_route');
    } catch (e) {
      print('Erro ao salvar no banco: $e');
      errorMessage.value = "Erro ao processar início da entrega localmente.";
    }
  }
}

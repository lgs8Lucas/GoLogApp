import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:golog/data/datasource/local/delivery_sql_service.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/local/sql_service.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/data/repository/route_repository.dart';
import 'package:golog/presentation/controller/sync_controller.dart';
import 'package:golog/util/log.dart';

class RouteController extends GetxController {
  static const String _keyActiveTransport = 'active_transport_id';

  final RouteRepository _routeRepository;
  final OccurrenceSqlService _occurrenceSqlService;
  final UserSqlService _userSqlService;
  final DeliverySqlService _deliverySqlService;
  final SqlService _sqlService;
  final GetStorage _storage;
  final SyncController _syncController;

  RouteController(
    this._routeRepository,
    this._occurrenceSqlService,
    this._userSqlService,
    this._deliverySqlService,
    this._sqlService,
    this._storage,
    this._syncController,
  );

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var transportList = <Transport>[].obs;

  /// Rota/parada que o motorista está visualizando.
  Transport? selectedTransport;
  Delivery? selectedDelivery;

  /// Rota em execução (cujo trajeto está sendo gravado). Persistida para
  /// sobreviver ao app ser fechado no meio da rota.
  Transport? activeTransport;

  bool get inProgress => activeTransport != null;

  Future<void> fetchTransports() async {
    try {
      isLoading(true);
      final data = await _routeRepository.getTransports();
      data.sort((a, b) => a.codeTransport.compareTo(b.codeTransport));
      transportList.assignAll(data);
      _rebindSelection();
    } catch (e) {
      appLog('Erro ao buscar transportes: $e');
      errorMessage.value = 'Não foi possível carregar as rotas.';
    } finally {
      isLoading(false);
    }
  }

  /// Depois de recarregar a lista, os objetos são novos: reaponta as
  /// seleções e restaura a rota ativa salva.
  void _rebindSelection() {
    Transport? byId(String? id) =>
        id == null ? null : transportList.firstWhereOrNull((t) => t.id == id);

    selectedTransport = byId(selectedTransport?.id);
    final deliveryId = selectedDelivery?.id;
    selectedDelivery = deliveryId == null
        ? null
        : selectedTransport?.deliveries.firstWhereOrNull(
            (d) => d.id == deliveryId,
          );

    final active = byId(_storage.read<String>(_keyActiveTransport));
    if (active != null && active.hasPendingDeliveries) {
      activeTransport = active;
    } else {
      _setActive(null);
    }
  }

  void _setActive(Transport? transport) {
    activeTransport = transport;
    if (transport == null) {
      _storage.remove(_keyActiveTransport);
    } else {
      _storage.write(_keyActiveTransport, transport.id);
    }
  }

  /// Para de gravar o trajeto (botão "Finalizar rota").
  void stopTracking() => _setActive(null);

  /// Chamado ao finalizar uma parada: se não sobrou nenhuma pendente na
  /// rota ativa, encerra a gravação do trajeto.
  void onDeliveryFinished() {
    transportList.refresh();
    final active = activeTransport;
    if (active != null && !active.hasPendingDeliveries) stopTracking();
  }

  void goToDetails(Transport transport) {
    selectedTransport = transport;
    Get.toNamed('/route_details');
  }

  void clearError() {
    errorMessage.value = '';
  }

  /// Limpa todo o estado em memória (logout).
  void reset() {
    transportList.clear();
    selectedTransport = null;
    selectedDelivery = null;
    _setActive(null);
    errorMessage.value = '';
  }

  /// Inicia a primeira parada pendente da rota selecionada.
  Future<void> startRoute() async {
    final transport = selectedTransport;
    if (transport == null) return;
    final next = Delivery.sortedBySequence(
      transport.deliveries,
    ).firstWhereOrNull((d) => !d.isFinished);
    if (next != null) await startDelivery(next);
  }

  /// Registra o início (ou a continuação) da parada e abre a navegação.
  Future<void> startDelivery(Delivery delivery) async {
    final transport = selectedTransport;
    if (transport == null || delivery.isFinished) return;

    final senderId = await _userSqlService.getCurrentUserId();

    Occurrence occurrence(OccurrenceType type, String description) =>
        Occurrence(
          type: type.name,
          description: description,
          attachment: '',
          deliveryId: delivery.id,
          transportId: transport.id,
          senderId: senderId,
          isSynced: false,
          dateTime: DateTime.now(),
        );

    try {
      if (!delivery.isStarted) {
        await _sqlService.db.transaction((txn) async {
          await _occurrenceSqlService.insertOccurrence(
            occurrence(OccurrenceType.Inicio, 'Início da rota'),
            txn: txn,
          );
          await _deliverySqlService.updateStatus(
            delivery,
            DeliveryStatus.started,
            txn: txn,
          );
        });
        delivery.status = DeliveryStatus.started;
        transportList.refresh();
      } else {
        await _occurrenceSqlService.insertOccurrence(
          occurrence(OccurrenceType.Continuando, 'Continuação da rota'),
        );
      }

      // Envia já o Início/Continuação (o ciclo de 3 min fica de reserva).
      _syncController.notifyNewRecord();

      // Só atualiza o estado e navega se o banco foi atualizado.
      selectedDelivery = delivery;
      _setActive(transport);
      Get.toNamed('/delivery_route');
    } catch (e) {
      appLog('Erro ao salvar no banco: $e');
      errorMessage.value = 'Erro ao processar início da entrega localmente.';
    }
  }
}

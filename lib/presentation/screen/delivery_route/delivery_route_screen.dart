import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/location_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/presentation/controller/occurrence_controller.dart';
import 'package:gologapp/presentation/screen/delivery_route/delivery_route_view.dart';
import 'package:gologapp/presentation/screen/events/occurrence_screen.dart';
import 'package:gologapp/presentation/widgets/map_placeholder.dart';
import 'package:gologapp/util/map_utils.dart';
import 'package:gologapp/util/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Liga os controllers ao layout puro [DeliveryRouteView], monta o mapa e
/// controla a regra de saída (só sai após registrar um desfecho).
class DeliveryRouteScreen extends StatefulWidget {
  const DeliveryRouteScreen({super.key});

  @override
  State<DeliveryRouteScreen> createState() => _DeliveryRouteScreenState();
}

class _DeliveryRouteScreenState extends State<DeliveryRouteScreen> {
  final LocationController locationController = Get.find<LocationController>();
  final RouteController controller = Get.find<RouteController>();
  final OccurrenceController occurrenceController =
      Get.find<OccurrenceController>();

  // Só libera a saída da entrega depois de um desfecho registrado (entregue
  // ou não). Começa bloqueado até a primeira checagem assíncrona terminar.
  bool _canLeave = false;

  @override
  void initState() {
    super.initState();
    _refreshOutcomeStatus();
  }

  Future<void> _refreshOutcomeStatus() async {
    final delivery = controller.selectedDelivery;
    final hasOutcome = delivery == null
        ? true
        : await occurrenceController.hasOutcomeOccurrence(delivery.id);
    if (mounted) setState(() => _canLeave = hasOutcome);
  }

  void _showOutcomeRequiredWarning() {
    Get.snackbar(
      'Ocorrência necessária',
      'Registre a entrega ou uma ocorrência antes de sair desta parada.',
      backgroundColor: Styles.COLOR_WHITE,
      colorText: Styles.COLOR_TEXT,
      icon: const Icon(Icons.info_outline_rounded, color: Styles.COLOR_ORANGE),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _openOccurrence(ActionType action) {
    occurrenceController.startNewOccurrence(action);
    Get.to(() => OccurrenceScreen())?.then((_) => _refreshOutcomeStatus());
  }

  Widget _buildMap() {
    final delivery = controller.selectedDelivery;
    final bool hasTruck =
        locationController.latitude.value != 0.0 ||
        locationController.longitude.value != 0.0;
    final truckPosition = LatLng(
      locationController.latitude.value,
      locationController.longitude.value,
    );

    // Destino só é válido se o backend realmente informou coordenadas
    // (o model usa 0,0 como valor padrão quando não vem preenchido).
    final hasDestination =
        delivery != null &&
        (delivery.destinationLat != 0.0 || delivery.destinationLng != 0.0);
    final destinationPosition = hasDestination
        ? LatLng(delivery.destinationLat, delivery.destinationLng)
        : null;

    // Fallback: sem GPS e sem destino não há onde centralizar o mapa
    // (antes ele abria em 0,0, no meio do oceano).
    if (!hasTruck && destinationPosition == null) {
      final bool locating = locationController.errorMessage.value.isEmpty;
      return MapPlaceholder(
        loading: locating,
        icon: Icons.location_off_outlined,
        message: locating
            ? 'Obtendo sua localização…'
            : 'Localização indisponível',
      );
    }

    final plannedRoute = MapUtils.getCoordinates(delivery?.routePlanned ?? '');
    // Se o trecho planejado não veio do backend, mostra ao menos uma linha
    // reta até o destino, que vai se atualizando conforme o motorista anda.
    final routePoints = plannedRoute.isNotEmpty
        ? plannedRoute
        : (destinationPosition != null && hasTruck
              ? [truckPosition, destinationPosition]
              : <LatLng>[]);

    final center = hasTruck ? truckPosition : destinationPosition!;

    return MapUtils.getDeliveryMap(
      truckPosition: center,
      centerPosition: center,
      height: 300,
      followTruck: hasTruck,
      routePoints: routePoints,
      stopPoints: destinationPosition != null ? [destinationPosition] : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showOutcomeRequiredWarning();
      },
      child: Obx(
        () => DeliveryRouteView(
          delivery: controller.selectedDelivery,
          routeCode: controller.selectedTransport?.codeTransport,
          locationError: locationController.errorMessage.value,
          // _buildMap lê os observáveis de localização diretamente dentro
          // deste Obx, então o mapa acompanha o GPS.
          map: _buildMap(),
          onBack: () {
            if (_canLeave) {
              Get.offAllNamed('/route_details');
            } else {
              _showOutcomeRequiredWarning();
            }
          },
          onRegisterDelivery: () => _openOccurrence(ActionType.signature),
          onRegisterOccurrence: () => _openOccurrence(ActionType.observation),
          onFinishRoute: () => _openOccurrence(ActionType.finish),
        ),
      ),
    );
  }
}

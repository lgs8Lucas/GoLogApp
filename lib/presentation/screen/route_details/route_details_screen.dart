import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/presentation/controller/location_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/screen/route_details/route_details_view.dart';
import 'package:golog/presentation/widgets/map_placeholder.dart';
import 'package:golog/util/map_utils.dart';
import 'package:golog/util/styles.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Liga os controllers ao layout puro [RouteDetailsView] e monta o mapa.
class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({super.key});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final LocationController locationController = Get.find<LocationController>();
  final RouteController routeController = Get.find<RouteController>();
  bool _isStarting = false;

  Future<void> _start() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      await routeController.startRoute();
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _onTapDelivery(Delivery delivery) {
    if (delivery.status == 'Finalizado') {
      Get.snackbar(
        'Parada concluída',
        'Esta parada já foi finalizada.',
        backgroundColor: Styles.COLOR_WHITE,
        colorText: Styles.COLOR_TEXT,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Styles.COLOR_LIGHTGREEN,
        ),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    routeController.goToDeliveryRoute(delivery);
  }

  Widget _buildMap(List<Delivery> deliveries) {
    final positions = MapUtils.getCoordinates(
      routeController.selectedTransport?.routePlanned ?? '',
    );
    final stops = deliveries
        .where((d) => d.destinationLat != 0.0 || d.destinationLng != 0.0)
        .map(
          (d) =>
              LatLng(latitude: d.destinationLat, longitude: d.destinationLng),
        )
        .toList();

    // Fallback: sem rota planejada nem paradas com coordenadas não há o que
    // desenhar — antes, `positions.first` derrubava a tela nesse caso.
    if (positions.isEmpty && stops.isEmpty) {
      return const MapPlaceholder(
        message: 'Rota sem coordenadas',
        icon: Icons.wrong_location_outlined,
      );
    }

    final centerAndZoom = MapUtils.getCenterAndZoom(
      positions.isNotEmpty ? positions : stops,
    );

    return MapUtils.getMap(
      centerPosition: centerAndZoom['center'],
      zoom: centerAndZoom['zoom'],
      height: 240,
      routePoints: [...positions],
      stopPoints: [if (positions.isNotEmpty) positions.first, ...stops],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // selectedTransport/selectedDelivery são campos simples, não
      // observáveis — quem avisa que uma entrega mudou de status (ex: ao
      // registrar uma ocorrência em DeliveryRouteScreen) é
      // routeController.transportList.refresh(). Sem ler transportList
      // aqui, este Obx nunca saberia que precisa reconstruir.
      routeController.transportList.length;

      final deliveries = Delivery.sortedBySequence(
        routeController.selectedTransport?.deliveries ?? [],
      );

      return RouteDetailsView(
        transport: routeController.selectedTransport,
        deliveries: deliveries,
        map: _buildMap(deliveries),
        errorMessage: routeController.errorMessage.value,
        locationError: locationController.errorMessage.value,
        onDismissError: routeController.clearError,
        onBack: () => Get.offAllNamed('/route_screen'),
        onTapDelivery: _onTapDelivery,
        onStart: _start,
        isStarting: _isStarting,
      );
    });
  }
}

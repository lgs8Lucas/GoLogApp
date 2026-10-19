import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/location_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/presentation/controller/occurrence_controller.dart';
import 'package:gologapp/presentation/screen/events/occurrence_screen.dart';
import 'package:gologapp/util/map_utils.dart';
import 'package:gologapp/util/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      'Registre uma ocorrência (entregue ou não) antes de sair desta entrega.',
      backgroundColor: Styles.COLOR_WHITE,
      colorText: Styles.COLOR_RED,
      snackPosition: SnackPosition.BOTTOM,
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
      child: Scaffold(
        backgroundColor: Styles.COLOR_BLACKBLUE,
        appBar: AppBar(
          title: Text(
            'Rota #${controller.selectedTransport?.codeTransport.toString().padLeft(3, '0') ?? '---'}',
            style: TextStyle(
              color: Styles.COLOR_WHITE,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.reply,
                color: Styles.COLOR_LIGHTGREEN,
                size: 28,
              ),
              onPressed: () {
                if (_canLeave) {
                  Get.offAllNamed('/route_details');
                } else {
                  _showOutcomeRequiredWarning();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: Styles.COLOR_BACKGROUND,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildDeliveryInfo(),
                      Expanded(
                        child: Obx(() => _buildMapSection(locationController)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Styles.COLOR_BACKGROUND,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${controller.selectedDelivery?.isPickup ?? false ? 'Coleta' : 'Entrega'} #${controller.selectedDelivery?.deliverySequence.toString().padLeft(3, '0') ?? '---'}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                controller.selectedDelivery?.status.toUpperCase() ?? '',
                style: TextStyle(
                  color: controller.selectedDelivery?.status == "Finalizado"
                      ? Colors.green
                      : Styles.COLOR_GRAY,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            controller.selectedDelivery?.destinationAddress ??
                'Endereço não disponível',
          ),
          if (controller.selectedDelivery != null)
            _infoRow(
              "Data prevista: ${controller.selectedDelivery!.shedulind.day.toString().padLeft(2, '0')}/${controller.selectedDelivery!.shedulind.month.toString().padLeft(2, '0')}/${controller.selectedDelivery!.shedulind.year} : ${controller.selectedDelivery!.shedulind.hour.toString().padLeft(2, '0')}:${controller.selectedDelivery!.shedulind.minute.toString().padLeft(2, '0')}",
            ),
          Row(
            children: [
              const Text(
                "Tempo restante: ",
                style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 16),
              ),
              /*
              Obx(
                () => Text(
                  null ?? 'Tempo não disponível',
                  style: const TextStyle(
                    color: Styles.COLOR_LIGHTGREEN,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              */
            ],
          ),
          const SizedBox(height: 15),
          _infoRow(
            "Destinatário: ${controller.selectedDelivery?.recipientName ?? 'Destinatário não disponível'}",
          ),
          const SizedBox(height: 15),
          Column(
            children: [
              /*
              Obx(
                () => Text(
                  "${(0 * 100).toInt()}%",
                  style: const TextStyle(
                    color: Styles.COLOR_LIGHTGREEN,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),*/
              const SizedBox(height: 4),
              /*
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Obx(
                  () => LinearProgressIndicator(
                    value: 0,
                    backgroundColor: Colors.white,
                    color: Styles.COLOR_LIGHTGREEN,
                    minHeight: 8,
                  ),
                ),
              ),
              */
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Styles.COLOR_GRAY, fontSize: 16),
      ),
    );
  }

  Widget _buildMapSection(LocationController locationController) {
    final delivery = controller.selectedDelivery;
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

    final plannedRoute = MapUtils.getCoordinates(delivery?.routePlanned ?? '');
    // Se o trecho planejado não veio do backend, mostra ao menos uma linha
    // reta até o destino, que vai se atualizando conforme o motorista anda.
    final routePoints = plannedRoute.isNotEmpty
        ? plannedRoute
        : (destinationPosition != null
              ? [truckPosition, destinationPosition]
              : <LatLng>[]);

    return Stack(
      children: [
        MapUtils.getDeliveryMap(
          truckPosition: truckPosition,
          centerPosition: truckPosition,
          height: 300,
          routePoints: routePoints,
          stopPoints: destinationPosition != null ? [destinationPosition] : [],
        ),
        Positioned(
          bottom: 20,
          left: 15,
          right: 15,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      "Registrar entrega",
                      Styles.COLOR_LIGHTGREEN,

                      () {
                        Get.find<OccurrenceController>().currentAction.value =
                            ActionType.signature;
                        Get.to(() => OccurrenceScreen())?.then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _actionButton(
                      "Registrar Ocorrência",
                      Styles.COLOR_ORANGE,
                      () {
                        Get.find<OccurrenceController>().currentAction.value =
                            ActionType.observation;
                        Get.to(() => OccurrenceScreen())?.then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: 200,
                child: _actionButton("Encerrar Rota", Styles.COLOR_RED, () {
                  Get.find<OccurrenceController>().currentAction.value =
                      ActionType.finish;
                  Get.to(() => OccurrenceScreen())?.then((_) {
                    if (mounted) {
                      setState(() {});
                    }
                  });
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

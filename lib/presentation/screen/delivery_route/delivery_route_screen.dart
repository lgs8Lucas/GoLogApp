import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/location_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/presentation/controller/occurrence_controller.dart';
import 'package:gologapp/presentation/screen/events/occurrence_screen.dart';
import 'package:gologapp/util/map_utils.dart';
import 'package:gologapp/util/styles.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DeliveryRouteScreen extends StatelessWidget {
  final LocationController locationController = Get.find<LocationController>();
  final RouteController controller = Get.find<RouteController>();

  DeliveryRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Get.offAllNamed('/route_details');
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
                    Expanded(child: _buildMapSection(locationController)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
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
    return Stack(
      children: [
        MapUtils.getDeliveryMap(
          truckPosition: Position(
            locationController.longitude.value,
            locationController.latitude.value,
          ), // Longitude, Latitude
          centerPosition: Position(
            locationController.longitude.value,
            locationController.latitude.value,
          ), // Longitude, Latitude
          height: 300,
          routePoints: [
            ...MapUtils.getCoordinates(
              controller.selectedDelivery?.routePlanned ?? '',
            ),
          ],
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
                        Get.to(() => OccurrenceScreen());
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
                        Get.to(() => OccurrenceScreen());
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
                  Get.to(() => OccurrenceScreen());
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

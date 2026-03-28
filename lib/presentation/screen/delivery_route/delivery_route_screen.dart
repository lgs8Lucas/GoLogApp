import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/screen/events/event_page.dart';
import 'package:gologapp/util/styles.dart';
import 'package:latlong2/latlong.dart';

class DeliveryController extends GetxController {
  var progress = 0.15.obs;
  var timeLeft = "1m 45s".obs;
  var routeNumber = 1.obs;
  var deliveryNumber = 1.obs;
  var deliveryDate = DateTime.now().obs;
  var recipient = "Lucas Gonçalves Silva".obs;
  var address = "Rua X, Jardim ABC, 1455".obs;
}

class DeliveryRouteScreen extends StatelessWidget {
  final controller = Get.put(DeliveryController());

  DeliveryRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      appBar: AppBar(
        title: Text(
          'Rota #${controller.routeNumber.value.toString().padLeft(3, '0')}',
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
              Get.offAllNamed('/route_datails');
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
                    Expanded(child: _buildMapSection()),
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
          Text(
            "Entrega #${controller.deliveryNumber.value.toString().padLeft(3, '0')}",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _infoRow(controller.address.value),
          _infoRow(
            "Data prevista: ${controller.deliveryDate.value.day}/${controller.deliveryDate.value.month}/${controller.deliveryDate.value.year}",
          ),
          Row(
            children: [
              const Text(
                "Tempo restante: ",
                style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 16),
              ),
              Obx(
                () => Text(
                  controller.timeLeft.value,
                  style: const TextStyle(
                    color: Styles.COLOR_LIGHTGREEN,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          _infoRow("Destinatário: ${controller.recipient.value}"),
          const SizedBox(height: 15),
          Column(
            children: [
              Obx(
                () => Text(
                  "${(controller.progress.value * 100).toInt()}%",
                  style: const TextStyle(
                    color: Styles.COLOR_LIGHTGREEN,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Obx(
                  () => LinearProgressIndicator(
                    value: controller.progress.value,
                    backgroundColor: Colors.white,
                    color: Styles.COLOR_LIGHTGREEN,
                    minHeight: 8,
                  ),
                ),
              ),
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

  Widget _buildMapSection() {
    final LatLng loc = const LatLng(-22.3572, -47.3846);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: loc,
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.gologapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: loc,
                  width: 50,
                  height: 50,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                ),
              ],
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
                        Get.to(
                          () => OccurrenceActionScreen(),
                          arguments: ActionType.signature,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _actionButton(
                      "Registrar Ocorrência",
                      Styles.COLOR_ORANGE,
                      () {
                        Get.to(
                          () => OccurrenceActionScreen(),
                          arguments: ActionType.observation,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: 200,
                child: _actionButton("Encerrar Rota", Styles.COLOR_RED, () {
                  Get.to(
                    () => OccurrenceActionScreen(),
                    arguments: ActionType.observation,
                  );
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

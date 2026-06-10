import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/presentation/controller/location_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/util/map_utils.dart';
import 'package:gologapp/util/styles.dart';
import 'package:gologapp/presentation/screen/route_details/widget/route_item_details.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteDetailsScreen extends StatelessWidget {
  RouteDetailsScreen({super.key});

  final LocationController locationController = Get.find<LocationController>();
  final RouteController routeController = Get.find<RouteController>();

  @override
  Widget build(BuildContext context) {
    List<Delivery> deliveries = Delivery.sortedBySequence(routeController.selectedTransport?.deliveries ?? []);
    List<Position> positions = MapUtils.getCoordinates(routeController.selectedTransport?.routePlanned ?? '');
    Map<String, dynamic> centerAndZoom = MapUtils.getCenterAndZoom(positions);
    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      appBar: AppBar(
        title: Text(
          "Rota #${routeController.selectedTransport?.codeTransport.toString().padLeft(3, '0') ?? '---'}",
          style: const TextStyle(
            color: Styles.COLOR_WHITE,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.reply,
              color: Styles.COLOR_LIGHTGREEN,
              size: 28,
            ),
            onPressed: () {
              Get.offAllNamed('/route_screen');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Styles.COLOR_BACKGROUND,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_shipping, size: 35),
                          const SizedBox(width: 10),
                          Text(
                            routeController.selectedTransport?.plate ?? '---',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 35),
                          const SizedBox(width: 10),
                          Text(
                            routeController.selectedTransport?.deliveryQuantity
                                    .toString() ??
                                '---',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  MapUtils.getMap(
                    truckPosition:
                        locationController.truckPosition, 
                    centerPosition:
                        centerAndZoom['center'],
                    zoom:
                        centerAndZoom['zoom'],

                    height: 300,
                    routePoints: [
                      ...positions
                    ],
                    stopPoints: [
                      positions.first,
                      ...deliveries.map((d) => Position(d.destinationLng, d.destinationLat)),
                    ]
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        "Paradas:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: deliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = deliveries[index];
                        final bool isFinalized = delivery.status == "Finalizado";

                        return GestureDetector(
                          onTap: isFinalized
                              ? () => Get.snackbar(
                                    "Aviso",
                                    "Esta parada já foi concluída.",
                                    backgroundColor: Styles.COLOR_WHITE,
                                    colorText: Styles.COLOR_ORANGE,
                                  )
                              : () => routeController.goToDeliveryRoute(delivery),
                          child: Opacity(
                            opacity: isFinalized ? 0.6 : 1.0,
                            child: Stack(
                              children: [
                                RouteItemDetails(delivery),
                                Positioned(
                                  top: 18,
                                  right: 20,
                                  child: Text(
                                    delivery.status.toUpperCase(),
                                    style: TextStyle(
                                      color: isFinalized ? Colors.green : Styles.COLOR_GRAY,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Botão de iniciar
                  ElevatedButton(
                    onPressed: () {
                      routeController.startRoute();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Styles.COLOR_LIGHTGREEN,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Iniciar",
                      style: TextStyle(
                        color: Styles.COLOR_WHITE,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

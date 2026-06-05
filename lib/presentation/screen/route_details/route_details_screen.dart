import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      appBar: AppBar(
        title: Text(
          "Rota #${routeController.selectedTransport?.id ?? '---'}",
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
                    truckPosition: Position(
                      -47.3732,
                      -22.3705,
                    ), // Longitude, Latitude
                    centerPosition: Position(
                      -47.3846,
                      -22.3575,
                    ), // Longitude, Latitude
                    height: 300,
                    routePoints: [
                      Position(-47.3732, -22.3705),
                      Position(-47.3846, -22.3575),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        "Entregas",
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
                      itemCount:
                          routeController
                              .selectedTransport
                              ?.deliveries
                              .length ??
                          0,
                      itemBuilder: (context, index) {
                        final delivery = routeController
                            .selectedTransport!
                            .deliveries[index];
                        return GestureDetector(
                          child: RouteItemDetails(delivery),
                        );
                      },
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

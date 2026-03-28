import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/screen/route_details/widget/map.dart';
import 'package:gologapp/util/styles.dart';
import 'package:latlong2/latlong.dart'; // Sem isso, o LatLng fica vermelho

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      appBar: AppBar(
        title: const Text(
          "Rota #001",
          style: TextStyle(
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
              Icons.logout,
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
                          const Text(
                            "EZP7A66",
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
                          const Text(
                            "4",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const MapWidget(
                    center: LatLng(-22.3575, -47.3846),
                    height: 300,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.map,
                      color: Styles.COLOR_LIGHTGREEN,
                      size: 28,
                    ),
                    onPressed: () {
                      Get.offAllNamed('/delivery_route');
                    },
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

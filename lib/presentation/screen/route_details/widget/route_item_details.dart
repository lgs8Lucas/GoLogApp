import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/util/styles.dart';
import 'package:gologapp/presentation/controller/route_detials_controller.dart';

class RouteItemDetails extends StatelessWidget {
  const RouteItemDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final RouteDetailsController controller = Get.put(RouteDetailsController());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 30,
            color: Styles.COLOR_BLACK,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Rota #001",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.error_outlined, // Ou Icons.schedule
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
                Text(
                  "Data prevista: 28/03/2026 14:30",
                  style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 15),
                ),
                Text(
                  "Endereço: Av. Dr. Maximiliano Baruto, 500 - Jardim Universitario, Araras - SP, 13607-339",
                  style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 15),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right, color: Styles.COLOR_GRAY),
            onPressed: () {
              controller.goToDetaisl();
            },
          ),
        ],
      ),
    );
  }
}

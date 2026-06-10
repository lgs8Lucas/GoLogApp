import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/util/date_extensions.dart';
import 'package:gologapp/util/styles.dart';

class RouteItemDetails extends StatelessWidget {
  final Delivery delivery;

  const RouteItemDetails(this.delivery, {super.key});

  @override
  Widget build(BuildContext context) {
    final RouteController controller = Get.put(RouteController());

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
                    Text(
                      "${delivery.isPickup ? 'Coleta' : 'Entrega'} ${delivery.deliverySequence}",
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
                  "Data prevista: ${delivery.shedulind.toDisplayFormat()}",
                  style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 15),
                ),
                Text(
                  "Endereço: ${delivery.destinationAddress}",
                  style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 15),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right, color: Styles.COLOR_GRAY),
            onPressed: () {
              controller.goToDeliveryRoute(delivery);
            },
          ),
        ],
      ),
    );
  }
}

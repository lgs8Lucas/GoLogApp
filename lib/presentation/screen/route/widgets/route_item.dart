import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/util/date_extensions.dart';
import 'package:gologapp/util/styles.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';

class RouteItemWidget extends StatelessWidget {
  final Transport transport;

  const RouteItemWidget({super.key, required this.transport});

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
            color: Styles.COLOR_BLACKBLUE,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rota #${transport.codeTransport.toString().padLeft(3, '0')}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Início previsto: ${DateTime.now().toDisplayFormat()}",
                  style: const TextStyle(
                    color: Styles.COLOR_GRAY,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Paradas: ${transport.deliveryQuantity}",
                  style: const TextStyle(
                    color: Styles.COLOR_GRAY,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right, color: Styles.COLOR_GRAY),
            onPressed: () {
              controller.goToDetails(transport);
            },
          ),
        ],
      ),
    );
  }
}

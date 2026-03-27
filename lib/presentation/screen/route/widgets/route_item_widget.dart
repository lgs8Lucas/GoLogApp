import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/util/styles.dart';

class RouteItemWidget extends StatelessWidget {
  const RouteItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  "Rota #001",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Início previsto: 30/11/2025 14:30",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  "Entregas: 4",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_right, color: Colors.grey),
        ],
      ),
    );
  }
}

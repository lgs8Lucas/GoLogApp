import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/presentation/controller/login_controller.dart';
import 'package:gologapp/presentation/controller/route_controller.dart';
import 'package:gologapp/util/styles.dart';
import 'widgets/route_item.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    final RouteController routeController = Get.find<RouteController>();

    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      appBar: AppBar(
        title: const Text(
          'Rotas',
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
              Icons.logout,
              color: Styles.COLOR_LIGHTGREEN,
              size: 28,
            ),
            onPressed: () async {
              await loginController.logout();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rotas de entrega',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Styles.COLOR_BLACKBLUE,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Obx(() {
                      if (routeController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Styles.COLOR_BLACKBLUE,
                          ),
                        );
                      }
                      return RefreshIndicator(
                        color: Styles
                            .COLOR_BLACKBLUE, 
                        onRefresh: () async {
                          await routeController.fetchTransports();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: routeController.transportList.isEmpty
                              ? 1
                              : routeController.transportList.length,
                          itemBuilder: (context, index) {
                            if (routeController.transportList.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 50),
                                child: Center(
                                  child: Text('Nenhuma rota encontrada.'),
                                ),
                              );
                            }
                            final transport =
                                routeController.transportList[index];

                            return GestureDetector(
                              child: RouteItemWidget(
                                transport: transport,
                              ),
                            );
                          },
                        ),
                      );
                    }),
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

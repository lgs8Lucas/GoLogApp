import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/util/styles.dart';

enum ActionType { signature, observation }

class OccurrenceActionController extends GetxController {
  var currentAction = ActionType.signature.obs; 
  final observationTextController = TextEditingController();

  void toggleAction() {
    if (currentAction.value == ActionType.signature) {
      currentAction.value = ActionType.observation;
    } else {
      currentAction.value = ActionType.signature;
    }
  }

  @override
  void onClose() {
    observationTextController.dispose();
    super.onClose();
  }
}

class OccurrenceActionScreen extends StatelessWidget {
  final controller = Get.put(OccurrenceActionController());

  OccurrenceActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Styles.COLOR_BACKGROUND, // Usando sua cor de fundo
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        controller.currentAction.value == ActionType.signature
                            ? "Assinatura"
                            : "Encerrar rota",
                        style: const TextStyle(
                          color: Styles.COLOR_BLACK,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: Obx(() {
                          if (controller.currentAction.value == ActionType.signature) {
                            return _buildSignatureArea();
                          } else {
                            return _buildObservationArea();
                          }
                        }),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Center(
                        child: Obx(() => _actionButton(
                          controller.currentAction.value == ActionType.signature
                              ? "Registrar entrega"
                              : "Concluir",
                          () {
                            // Ação real aqui
                            controller.toggleAction(); 
                          },
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Rota #001",
            style: TextStyle(
              color: Styles.COLOR_WHITE, // Usando sua cor branca
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.reply,
              color: Styles.COLOR_LIGHTGREEN, // Usando seu verde claro
              size: 30,
            ),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureArea() {
    return Container(
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            // TODO: Inserir canvas de assinatura aqui
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Container(width: 1, color: Styles.COLOR_BLACK), // Linha preta
          ),
          RotatedBox(
            quarterTurns: 3,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                "Responsável",
                style: TextStyle(
                  color: Styles.COLOR_BLACK,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Observação",
          style: TextStyle(color: Styles.COLOR_GRAY, fontSize: 14), // Seu cinza
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Styles.COLOR_WHITE,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: controller.observationTextController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintText: "Digite os detalhes aqui...",
                hintStyle: TextStyle(color: Styles.COLOR_LIGHTBLACK), // Seu preto claro
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Styles.COLOR_GRAY, // Ou COLOR_BLACK dependendo da preferência
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Styles.COLOR_WHITE,
          fontSize: 14,
        ),
      ),
    );
  }
}
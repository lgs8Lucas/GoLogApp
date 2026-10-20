import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gologapp/util/styles.dart';

// Banner reativo de erro: só ocupa espaço quando a mensagem observada não
// está vazia. Usado para dar feedback visual persistente de falhas (rede,
// permissão de localização, etc.) sem depender de um snackbar passageiro.
class ErrorBanner extends StatelessWidget {
  final RxString message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (message.value.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Styles.COLOR_WHITE,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Styles.COLOR_RED),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Styles.COLOR_RED, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.value,
                style: const TextStyle(color: Styles.COLOR_RED, fontSize: 14),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, color: Styles.COLOR_RED, size: 18),
                ),
              ),
          ],
        ),
      );
    });
  }
}

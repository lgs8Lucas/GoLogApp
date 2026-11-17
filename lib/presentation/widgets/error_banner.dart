import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

enum BannerType { error, warning, info }

/// Banner de feedback persistente (rede, permissão de localização etc.).
/// Versão "pura": recebe a mensagem como String e some quando ela é vazia.
class AppBanner extends StatelessWidget {
  final String message;
  final BannerType type;
  final VoidCallback? onDismiss;

  const AppBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();

    final (Color color, Color background, IconData icon) = switch (type) {
      BannerType.error => (
        Styles.COLOR_RED,
        Styles.COLOR_RED_SOFT,
        Icons.error_outline_rounded,
      ),
      BannerType.warning => (
        Styles.COLOR_ORANGE,
        Styles.COLOR_ORANGE_SOFT,
        Icons.location_off_outlined,
      ),
      BannerType.info => (
        Styles.COLOR_BLUE,
        Styles.COLOR_BLUE_SOFT,
        Icons.info_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Styles.SPACE_M),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Styles.RADIUS_M),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Styles.COLOR_TEXT,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Fechar',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, color: color, size: 18),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Banner reativo de erro: só ocupa espaço quando a mensagem observada não
/// está vazia. Mantido para quem já observa um RxString diretamente.
class ErrorBanner extends StatelessWidget {
  final RxString message;
  final VoidCallback? onDismiss;
  final BannerType type;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.type = BannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppBanner(message: message.value, onDismiss: onDismiss, type: type),
    );
  }
}

@Preview(group: 'Componentes', name: 'Banners', wrapper: goLogPreviewWrapper)
Widget appBannerPreview() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBanner(
          message: 'Erro ao buscar transportes: sem conexão com a internet.',
          onDismiss: () {},
        ),
        const AppBanner(
          message: 'Permissão de localização negada pelo usuário.',
          type: BannerType.warning,
        ),
        const AppBanner(
          message: 'Sincronizando ocorrências pendentes…',
          type: BannerType.info,
        ),
      ],
    ),
  );
}

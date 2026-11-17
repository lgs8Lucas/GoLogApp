import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/sync_status.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/presentation/screen/route_details/widget/route_item_details.dart';
import 'package:golog/presentation/widgets/app_button.dart';
import 'package:golog/presentation/widgets/error_banner.dart';
import 'package:golog/presentation/widgets/map_placeholder.dart';
import 'package:golog/presentation/widgets/page_shell.dart';
import 'package:golog/presentation/widgets/state_views.dart';
import 'package:golog/presentation/widgets/sync_indicator.dart';
import 'package:golog/preview/preview_data.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';

/// Layout puro da tela de detalhes da rota. O mapa chega pronto via [map]
/// para que o preview possa usar um [MapPlaceholder] no lugar do Google Maps.
class RouteDetailsView extends StatelessWidget {
  final Transport? transport;
  final List<Delivery> deliveries;
  final Widget map;
  final String errorMessage;
  final String locationError;
  final VoidCallback? onDismissError;
  final VoidCallback onBack;
  final ValueChanged<Delivery> onTapDelivery;
  final VoidCallback onStart;
  final bool isStarting;
  final SyncStatus? syncStatus;
  final VoidCallback? onSyncNow;

  const RouteDetailsView({
    super.key,
    required this.transport,
    required this.deliveries,
    required this.map,
    required this.onBack,
    required this.onTapDelivery,
    required this.onStart,
    this.errorMessage = '',
    this.locationError = '',
    this.onDismissError,
    this.isStarting = false,
    this.syncStatus,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final t = transport;
    if (t == null) {
      return PageShell(
        title: 'Rota',
        onBack: onBack,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Rota não encontrada',
          message: 'Volte para a lista e selecione uma rota novamente.',
          actionLabel: 'Voltar para rotas',
          actionIcon: Icons.arrow_back_rounded,
          onAction: onBack,
        ),
      );
    }

    final int done = deliveries.where((d) => d.isFinished).length;
    final bool allDone = deliveries.isNotEmpty && done == deliveries.length;
    final bool inProgress = deliveries.any((d) => d.isStarted);

    return PageShell(
      title: 'Rota ${FormatUtils.routeCode(t.codeTransport)}',
      subtitle: FormatUtils.orFallback(t.plate, 'Placa não informada'),
      onBack: onBack,
      contentPadding: EdgeInsets.zero,
      bottomBar: deliveries.isEmpty
          ? null
          : BottomActionBar(
              child: AppButton(
                label: allDone
                    ? 'Rota concluída'
                    : (inProgress ? 'Continuar rota' : 'Iniciar rota'),
                icon: allDone
                    ? Icons.verified_rounded
                    : Icons.play_arrow_rounded,
                isLoading: isStarting,
                onPressed: allDone ? null : onStart,
              ),
            ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverList.list(
              children: [
                if (syncStatus != null)
                  SyncIndicator(status: syncStatus!, onSyncNow: onSyncNow),
                AppBanner(message: errorMessage, onDismiss: onDismissError),
                AppBanner(message: locationError, type: BannerType.warning),
                _Summary(
                  plate: t.plate,
                  total: deliveries.isNotEmpty
                      ? deliveries.length
                      : t.deliveryQuantity,
                  done: done,
                ),
                const SizedBox(height: Styles.SPACE_M),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Styles.RADIUS_L),
                  child: SizedBox(height: 240, child: map),
                ),
                const SizedBox(height: Styles.SPACE_XL),
                Row(
                  children: [
                    const Text('Paradas', style: Styles.TITLE_M),
                    const Spacer(),
                    Text(
                      '$done de ${deliveries.length} concluídas',
                      style: Styles.CAPTION,
                    ),
                  ],
                ),
                const SizedBox(height: Styles.SPACE_M),
              ],
            ),
          ),
          if (deliveries.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.pin_drop_outlined,
                title: 'Sem paradas',
                message: 'Esta rota ainda não possui entregas ou coletas.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = deliveries[index];
                  return RouteItemDetails(
                    delivery,
                    isFirst: index == 0,
                    isLast: index == deliveries.length - 1,
                    onTap: () => onTapDelivery(delivery),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String plate;
  final int total;
  final int done;

  const _Summary({
    required this.plate,
    required this.total,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: Styles.SPACE_S,
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_shipping_outlined,
            label: 'Veículo',
            value: FormatUtils.orFallback(plate, '---'),
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.pin_drop_outlined,
            label: 'Paradas',
            value: '$total',
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.task_alt_rounded,
            label: 'Concluídas',
            value: '$done',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Styles.SPACE_M),
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_M),
        boxShadow: Styles.SHADOW_CARD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Styles.COLOR_LIGHTGREEN),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Styles.TITLE_S,
          ),
          Text(label, style: Styles.CAPTION),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Detalhes da rota',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeDetailsPreview() {
  final transport = PreviewData.transport();
  return RouteDetailsView(
    transport: transport,
    deliveries: transport.deliveries,
    map: const MapPlaceholder(message: 'Prévia do mapa da rota'),
    onBack: () {},
    onTapDelivery: (_) {},
    onStart: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Detalhes - sem GPS e sem paradas',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeDetailsEmptyPreview() {
  return RouteDetailsView(
    transport: PreviewData.transport(code: 42, plate: '', deliveries: []),
    deliveries: const [],
    map: const MapPlaceholder(message: 'Rota sem coordenadas'),
    locationError: 'Permissão de localização negada pelo usuário.',
    onBack: () {},
    onTapDelivery: (_) {},
    onStart: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Detalhes - rota não encontrada',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeDetailsNotFoundPreview() {
  return RouteDetailsView(
    transport: null,
    deliveries: const [],
    map: const SizedBox.shrink(),
    onBack: () {},
    onTapDelivery: (_) {},
    onStart: () {},
  );
}

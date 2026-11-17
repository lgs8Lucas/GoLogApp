import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/presentation/widgets/status_badge.dart';
import 'package:golog/preview/preview_data.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';

/// Card de uma rota na listagem. O card inteiro é tocável (antes só a
/// pequena seta era), com progresso de paradas concluídas.
class RouteItemWidget extends StatelessWidget {
  final Transport transport;
  final VoidCallback? onTap;

  const RouteItemWidget({super.key, required this.transport, this.onTap});

  @override
  Widget build(BuildContext context) {
    final deliveries = Delivery.sortedBySequence(transport.deliveries);
    final int total = deliveries.isNotEmpty
        ? deliveries.length
        : transport.deliveryQuantity;
    final int done = deliveries.where((d) => d.isFinished).length;
    final bool anyStarted = deliveries.any((d) => d.isStarted);
    final double progress = total == 0 ? 0 : done / total;

    final String routeStatus = total > 0 && done == total
        ? DeliveryStatus.finished
        : (anyStarted || done > 0
              ? DeliveryStatus.started
              : DeliveryStatus.pending);

    final String start = deliveries.isNotEmpty
        ? FormatUtils.dateTime(deliveries.first.scheduledDate)
        : 'Sem previsão';

    return Padding(
      padding: const EdgeInsets.only(bottom: Styles.SPACE_M),
      child: Material(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_L),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Styles.RADIUS_L),
          child: Container(
            padding: const EdgeInsets.all(Styles.SPACE_L),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Styles.RADIUS_L),
              boxShadow: Styles.SHADOW_CARD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Styles.COLOR_BLACKBLUE,
                        borderRadius: BorderRadius.circular(Styles.RADIUS_M),
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Styles.COLOR_LIGHTGREEN,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: Styles.SPACE_M),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rota ${FormatUtils.routeCode(transport.codeTransport)}',
                            style: Styles.TITLE_S,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                size: 14,
                                color: Styles.COLOR_TEXT_SECONDARY,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  FormatUtils.orFallback(
                                    transport.plate,
                                    'Placa não informada',
                                  ),
                                  style: Styles.CAPTION,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.fromStatus(routeStatus, compact: true),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Styles.COLOR_TEXT_HINT,
                    ),
                  ],
                ),
                const SizedBox(height: Styles.SPACE_M),
                const Divider(height: 1, color: Styles.COLOR_BORDER),
                const SizedBox(height: Styles.SPACE_M),
                Row(
                  children: [
                    Expanded(
                      child: _Meta(
                        icon: Icons.schedule_rounded,
                        label: 'Início previsto',
                        value: start,
                      ),
                    ),
                    _Meta(
                      icon: Icons.pin_drop_outlined,
                      label: 'Paradas',
                      value: '$done/$total',
                    ),
                  ],
                ),
                const SizedBox(height: Styles.SPACE_M),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Styles.COLOR_GRAY_SOFT,
                    color: Styles.COLOR_LIGHTGREEN,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Meta({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Styles.COLOR_LIGHTGREEN),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Styles.CAPTION,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Styles.LABEL,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'Card de rota',
  wrapper: goLogPreviewWrapper,
)
Widget routeItemPreview() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: PreviewData.transports()
          .map((t) => RouteItemWidget(transport: t, onTap: () {}))
          .toList(),
    ),
  );
}

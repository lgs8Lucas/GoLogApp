import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/presentation/widgets/status_badge.dart';
import 'package:golog/preview/preview_data.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';

/// Item de parada no formato de linha do tempo: número da sequência,
/// conector vertical e card com tipo, status, previsão, endereço e
/// destinatário. Paradas atrasadas ganham destaque em vermelho.
class RouteItemDetails extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  /// Permite fixar "agora" nos previews/testes.
  final DateTime? now;

  const RouteItemDetails(
    this.delivery, {
    super.key,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFinalized = delivery.status == 'Finalizado';
    final bool isLate =
        !isFinalized && delivery.shedulind.isBefore(now ?? DateTime.now());
    final StatusStyle status = StatusStyle.of(delivery.status);
    final Color dotColor = isLate ? Styles.COLOR_RED : status.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 18,
                  color: isFirst ? Colors.transparent : Styles.COLOR_BORDER,
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFinalized ? dotColor : Styles.COLOR_WHITE,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: isFinalized
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Styles.COLOR_WHITE,
                        )
                      : Text(
                          '${delivery.deliverySequence}',
                          style: TextStyle(
                            color: dotColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Styles.COLOR_BORDER,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Styles.SPACE_S),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Styles.SPACE_M),
              child: Opacity(
                opacity: isFinalized ? 0.65 : 1,
                child: Material(
                  color: Styles.COLOR_WHITE,
                  borderRadius: BorderRadius.circular(Styles.RADIUS_L),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(Styles.RADIUS_L),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                delivery.isPickup
                                    ? Icons.move_to_inbox_outlined
                                    : Icons.inventory_2_outlined,
                                size: 20,
                                color: Styles.COLOR_BLACKBLUE,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${delivery.isPickup ? 'Coleta' : 'Entrega'} ${delivery.deliverySequence}',
                                  style: Styles.TITLE_S,
                                ),
                              ),
                              StatusBadge(
                                style: isLate ? StatusStyle.late : status,
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _line(
                            Icons.schedule_rounded,
                            FormatUtils.dateTime(delivery.shedulind),
                            color: isLate ? Styles.COLOR_RED : null,
                          ),
                          _line(
                            Icons.place_outlined,
                            FormatUtils.address(delivery.destinationAddress),
                          ),
                          _line(
                            Icons.person_outline_rounded,
                            FormatUtils.orFallback(
                              delivery.recipientName,
                              'Destinatário não informado',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Styles.COLOR_TEXT_HINT),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Styles.BODY.copyWith(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'Parada (timeline)',
  wrapper: goLogPreviewWrapper,
)
Widget routeItemDetailsPreview() {
  final deliveries = PreviewData.deliveries();
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < deliveries.length; i++)
          RouteItemDetails(
            deliveries[i],
            isFirst: i == 0,
            isLast: i == deliveries.length - 1,
            now: DateTime(2026, 11, 11, 12),
            onTap: () {},
          ),
      ],
    ),
  );
}

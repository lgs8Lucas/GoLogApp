import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/presentation/widgets/app_button.dart';
import 'package:gologapp/presentation/widgets/error_banner.dart';
import 'package:gologapp/presentation/widgets/map_placeholder.dart';
import 'package:gologapp/presentation/widgets/page_shell.dart';
import 'package:gologapp/presentation/widgets/state_views.dart';
import 'package:gologapp/presentation/widgets/status_badge.dart';
import 'package:gologapp/preview/preview_data.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/format_utils.dart';
import 'package:gologapp/util/styles.dart';

/// Layout puro da tela de entrega em andamento: card com os dados da
/// parada, mapa ocupando o restante e painel de ações flutuante.
class DeliveryRouteView extends StatelessWidget {
  final Delivery? delivery;
  final int? routeCode;
  final Widget map;
  final String locationError;
  final VoidCallback onBack;
  final VoidCallback onRegisterDelivery;
  final VoidCallback onRegisterOccurrence;
  final VoidCallback onFinishRoute;

  const DeliveryRouteView({
    super.key,
    required this.delivery,
    required this.routeCode,
    required this.map,
    required this.onBack,
    required this.onRegisterDelivery,
    required this.onRegisterOccurrence,
    required this.onFinishRoute,
    this.locationError = '',
  });

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    return PageShell(
      title: 'Rota ${FormatUtils.routeCode(routeCode)}',
      subtitle: d == null
          ? null
          : '${d.isPickup ? 'Coleta' : 'Entrega'} ${FormatUtils.routeCode(d.deliverySequence)}',
      onBack: onBack,
      contentPadding: EdgeInsets.zero,
      child: d == null
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhuma parada selecionada',
              message: 'Volte para a rota e escolha uma parada para iniciar.',
              actionLabel: 'Voltar',
              actionIcon: Icons.arrow_back_rounded,
              onAction: onBack,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    children: [
                      AppBanner(
                        message: locationError,
                        type: BannerType.warning,
                      ),
                      _DeliveryInfoCard(delivery: d),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: map),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: SafeArea(
                          top: false,
                          child: _ActionPanel(
                            onRegisterDelivery: onRegisterDelivery,
                            onRegisterOccurrence: onRegisterOccurrence,
                            onFinishRoute: onFinishRoute,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  final Delivery delivery;

  const _DeliveryInfoCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Styles.SPACE_L),
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_L),
        boxShadow: Styles.SHADOW_CARD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Styles.COLOR_GREEN_SOFT,
                  borderRadius: BorderRadius.circular(Styles.RADIUS_M),
                ),
                child: Icon(
                  delivery.isPickup
                      ? Icons.move_to_inbox_outlined
                      : Icons.inventory_2_outlined,
                  color: Styles.COLOR_LIGHTGREEN,
                ),
              ),
              const SizedBox(width: Styles.SPACE_M),
              Expanded(
                child: Text(
                  '${delivery.isPickup ? 'Coleta' : 'Entrega'} ${FormatUtils.routeCode(delivery.deliverySequence)}',
                  style: Styles.TITLE_M,
                ),
              ),
              StatusBadge.fromStatus(delivery.status),
            ],
          ),
          const SizedBox(height: Styles.SPACE_M),
          _InfoLine(
            icon: Icons.place_outlined,
            label: 'Endereço',
            value: FormatUtils.address(delivery.destinationAddress),
          ),
          _InfoLine(
            icon: Icons.schedule_rounded,
            label: 'Data prevista',
            value: FormatUtils.dateTime(delivery.shedulind),
          ),
          _InfoLine(
            icon: Icons.person_outline_rounded,
            label: 'Destinatário',
            value: FormatUtils.orFallback(
              delivery.recipientName,
              'Não informado',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Styles.SPACE_S),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Styles.COLOR_TEXT_HINT),
          const SizedBox(width: Styles.SPACE_S),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Styles.CAPTION),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.BODY.copyWith(color: Styles.COLOR_TEXT),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final VoidCallback onRegisterDelivery;
  final VoidCallback onRegisterOccurrence;
  final VoidCallback onFinishRoute;

  const _ActionPanel({
    required this.onRegisterDelivery,
    required this.onRegisterOccurrence,
    required this.onFinishRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Styles.SPACE_M),
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_L),
        boxShadow: Styles.SHADOW_FLOATING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'Registrar entrega',
            icon: Icons.draw_outlined,
            onPressed: onRegisterDelivery,
          ),
          const SizedBox(height: Styles.SPACE_S),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Ocorrência',
                  icon: Icons.report_gmailerrorred_rounded,
                  color: Styles.COLOR_ORANGE,
                  variant: AppButtonVariant.outlined,
                  onPressed: onRegisterOccurrence,
                ),
              ),
              const SizedBox(width: Styles.SPACE_S),
              Expanded(
                child: AppButton(
                  label: 'Encerrar',
                  icon: Icons.flag_outlined,
                  color: Styles.COLOR_RED,
                  variant: AppButtonVariant.outlined,
                  onPressed: onFinishRoute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Entrega em andamento',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryRoutePreview() {
  return DeliveryRouteView(
    delivery: PreviewData.delivery(sequence: 2, status: 'Iniciado'),
    routeCode: 1,
    map: const MapPlaceholder(message: 'Prévia do mapa de navegação'),
    onBack: () {},
    onRegisterDelivery: () {},
    onRegisterOccurrence: () {},
    onFinishRoute: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Entrega - dados incompletos / sem GPS',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryRouteFallbackPreview() {
  return DeliveryRouteView(
    delivery: PreviewData.delivery(
      sequence: 3,
      address: ', , , , ',
      recipient: '',
      status: '',
    ),
    routeCode: null,
    map: const MapPlaceholder(
      loading: true,
      message: 'Obtendo sua localização…',
    ),
    locationError: 'O serviço de localização está desativado no aparelho.',
    onBack: () {},
    onRegisterDelivery: () {},
    onRegisterOccurrence: () {},
    onFinishRoute: () {},
  );
}

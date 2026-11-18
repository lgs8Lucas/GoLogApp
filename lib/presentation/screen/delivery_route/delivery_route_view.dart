import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/presentation/widgets/app_button.dart';
import 'package:golog/presentation/widgets/error_banner.dart';
import 'package:golog/presentation/widgets/map_placeholder.dart';
import 'package:golog/presentation/widgets/state_views.dart';
import 'package:golog/presentation/widgets/status_badge.dart';
import 'package:golog/preview/preview_data.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Fase da navegação turn-by-turn exibida no painel.
enum NavPhase { preparing, navigating, arrived, unavailable }

/// Estado da navegação, independente do SDK (para a View continuar pura
/// e renderizável no Widget Previewer).
class NavigationState {
  final NavPhase phase;
  final String? message;
  final double? remainingSeconds;
  final double? remainingMeters;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NavigationState({
    required this.phase,
    this.message,
    this.remainingSeconds,
    this.remainingMeters,
    this.actionLabel,
    this.onAction,
  });

  const NavigationState.preparing([this.message = 'Calculando a melhor rota…'])
    : phase = NavPhase.preparing,
      remainingSeconds = null,
      remainingMeters = null,
      actionLabel = null,
      onAction = null;
}

/// Layout puro da tela de navegação da entrega: o mapa de navegação ocupa
/// a tela inteira (com o cabeçalho de manobras do próprio SDK no topo) e um
/// painel inferior mostra tempo/distância restantes, dados da parada e as
/// ações de registro.
class DeliveryRouteView extends StatelessWidget {
  /// Altura aproximada reservada pelo painel; usada como padding do mapa
  /// para o ícone do motorista e o botão "recentralizar" não ficarem
  /// escondidos atrás dele.
  static const double panelReservedHeight = 330;

  final Delivery? delivery;
  final int? routeCode;
  final Widget map;
  final NavigationState navigation;
  final String locationError;
  final VoidCallback onBack;
  final VoidCallback onRegisterDelivery;
  final VoidCallback onRegisterOccurrence;
  final VoidCallback onFinishRoute;

  /// Fixa "agora" nos previews (horário de chegada).
  final DateTime? now;

  const DeliveryRouteView({
    super.key,
    required this.delivery,
    required this.routeCode,
    required this.map,
    required this.navigation,
    required this.onBack,
    required this.onRegisterDelivery,
    required this.onRegisterOccurrence,
    required this.onFinishRoute,
    this.locationError = '',
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    if (d == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhuma parada selecionada',
              message: 'Volte para a rota e escolha uma parada para navegar.',
              actionLabel: 'Voltar',
              actionIcon: Icons.arrow_back_rounded,
              onAction: onBack,
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Styles.COLOR_BACKGROUND,
        body: Stack(
          children: [
            Positioned.fill(child: map),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // Em iOS o mapa é uma platform view nativa: sem o
              // PointerInterceptor, toques no painel também mexeriam no mapa.
              child: PointerInterceptor(
                child: _BottomPanel(
                  delivery: d,
                  routeCode: routeCode,
                  navigation: navigation,
                  locationError: locationError,
                  onBack: onBack,
                  onRegisterDelivery: onRegisterDelivery,
                  onRegisterOccurrence: onRegisterOccurrence,
                  onFinishRoute: onFinishRoute,
                  now: now,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final Delivery delivery;
  final int? routeCode;
  final NavigationState navigation;
  final String locationError;
  final VoidCallback onBack;
  final VoidCallback onRegisterDelivery;
  final VoidCallback onRegisterOccurrence;
  final VoidCallback onFinishRoute;
  final DateTime? now;

  const _BottomPanel({
    required this.delivery,
    required this.routeCode,
    required this.navigation,
    required this.locationError,
    required this.onBack,
    required this.onRegisterDelivery,
    required this.onRegisterOccurrence,
    required this.onFinishRoute,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final String kind = delivery.isPickup ? 'Coleta' : 'Entrega';

    return Container(
      decoration: const BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Styles.RADIUS_XL),
        ),
        boxShadow: Styles.SHADOW_FLOATING,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Styles.COLOR_BORDER,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: Styles.SPACE_M),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$kind ${FormatUtils.routeCode(delivery.deliverySequence)}',
                          style: Styles.TITLE_M,
                        ),
                        Text(
                          'Rota ${FormatUtils.routeCode(routeCode)}',
                          style: Styles.CAPTION,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromStatus(delivery.status, compact: true),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'Voltar para a rota',
                    style: IconButton.styleFrom(
                      backgroundColor: Styles.COLOR_GRAY_SOFT,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Styles.COLOR_TEXT_SECONDARY,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Styles.SPACE_M),
              AppBanner(message: locationError, type: BannerType.warning),
              _NavigationStrip(navigation: navigation, now: now),
              const SizedBox(height: Styles.SPACE_M),
              _CompactLine(
                icon: Icons.place_outlined,
                text: FormatUtils.address(delivery.destinationAddress),
              ),
              _CompactLine(
                icon: Icons.person_outline_rounded,
                text: FormatUtils.orFallback(
                  delivery.recipientName,
                  'Destinatário não informado',
                ),
              ),
              const SizedBox(height: Styles.SPACE_M),
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
        ),
      ),
    );
  }
}

/// Faixa com o estado da navegação: tempo/distância/chegada enquanto
/// navega, aviso de chegada, carregamento ou motivo da indisponibilidade.
class _NavigationStrip extends StatelessWidget {
  final NavigationState navigation;
  final DateTime? now;

  const _NavigationStrip({required this.navigation, this.now});

  @override
  Widget build(BuildContext context) {
    switch (navigation.phase) {
      case NavPhase.navigating:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Styles.COLOR_BLACKBLUE,
            borderRadius: BorderRadius.circular(Styles.RADIUS_M),
          ),
          child: Row(
            children: [
              _Metric(
                label: 'Tempo',
                value: FormatUtils.duration(navigation.remainingSeconds),
              ),
              const _MetricDivider(),
              _Metric(
                label: 'Distância',
                value: FormatUtils.distance(navigation.remainingMeters),
              ),
              const _MetricDivider(),
              _Metric(
                label: 'Chegada',
                value: FormatUtils.arrivalTime(
                  navigation.remainingSeconds,
                  now: now,
                ),
              ),
            ],
          ),
        );
      case NavPhase.arrived:
        return _StatusStrip(
          icon: Icons.where_to_vote_rounded,
          color: Styles.COLOR_LIGHTGREEN,
          background: Styles.COLOR_GREEN_SOFT,
          title: 'Você chegou ao destino',
          message:
              navigation.message ??
              'Registre a entrega ou uma ocorrência para continuar.',
        );
      case NavPhase.preparing:
        return _StatusStrip(
          loading: true,
          color: Styles.COLOR_BLUE,
          background: Styles.COLOR_BLUE_SOFT,
          title: 'Preparando navegação',
          message: navigation.message ?? 'Calculando a melhor rota…',
        );
      case NavPhase.unavailable:
        return _StatusStrip(
          icon: Icons.wrong_location_outlined,
          color: Styles.COLOR_ORANGE,
          background: Styles.COLOR_ORANGE_SOFT,
          title: 'Navegação indisponível',
          message: navigation.message ?? 'Siga pelo endereço da parada.',
          actionLabel: navigation.actionLabel,
          onAction: navigation.onAction,
        );
    }
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Styles.COLOR_LIGHTGREEN,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Styles.COLOR_WHITE.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Styles.COLOR_WHITE.withValues(alpha: 0.15),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final IconData? icon;
  final bool loading;
  final Color color;
  final Color background;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusStrip({
    required this.color,
    required this.background,
    required this.title,
    required this.message,
    this.icon,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Styles.SPACE_M),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Styles.RADIUS_M),
      ),
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          else
            Icon(icon, color: color, size: 24),
          const SizedBox(width: Styles.SPACE_M),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Styles.LABEL),
                const SizedBox(height: 2),
                Text(message, style: Styles.BODY.copyWith(fontSize: 13)),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Styles.COLOR_TEXT_HINT),
          const SizedBox(width: Styles.SPACE_S),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.BODY.copyWith(color: Styles.COLOR_TEXT),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Previews
// ---------------------------------------------------------------------------

DeliveryRouteView _preview(
  NavigationState navigation, {
  Widget map = const MapPlaceholder(
    message: 'Prévia do mapa de navegação',
    icon: Icons.navigation_outlined,
  ),
  String locationError = '',
}) {
  return DeliveryRouteView(
    delivery: PreviewData.delivery(sequence: 2, status: DeliveryStatus.started),
    routeCode: 1,
    map: map,
    navigation: navigation,
    locationError: locationError,
    now: DateTime(2026, 11, 11, 14, 10),
    onBack: () {},
    onRegisterDelivery: () {},
    onRegisterOccurrence: () {},
    onFinishRoute: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Navegação - em rota',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryNavigatingPreview() => _preview(
  const NavigationState(
    phase: NavPhase.navigating,
    remainingSeconds: 1260,
    remainingMeters: 8400,
  ),
);

@Preview(
  group: 'Telas',
  name: 'Navegação - calculando rota',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryPreparingPreview() => _preview(
  const NavigationState.preparing(),
  map: const MapPlaceholder(loading: true, message: 'Iniciando navegação…'),
);

@Preview(
  group: 'Telas',
  name: 'Navegação - chegou',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryArrivedPreview() =>
    _preview(const NavigationState(phase: NavPhase.arrived));

@Preview(
  group: 'Telas',
  name: 'Navegação - indisponível',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget deliveryUnavailablePreview() => _preview(
  NavigationState(
    phase: NavPhase.unavailable,
    message: 'Sem conexão para calcular a rota.',
    actionLabel: 'Tentar',
    onAction: () {},
  ),
  map: const MapPlaceholder(
    message: 'Mapa indisponível',
    icon: Icons.cloud_off_rounded,
  ),
  locationError: 'O serviço de localização está desativado no aparelho.',
);

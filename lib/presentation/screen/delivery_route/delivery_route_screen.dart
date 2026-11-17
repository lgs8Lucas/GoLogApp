import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:golog/presentation/controller/location_controller.dart';
import 'package:golog/presentation/controller/occurrence_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/screen/delivery_route/delivery_route_view.dart';
import 'package:golog/presentation/screen/events/occurrence_screen.dart';
import 'package:golog/presentation/widgets/map_placeholder.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';

/// Tela de navegação turn-by-turn até a parada selecionada, usando o
/// Google Navigation SDK (google_navigation_flutter).
///
/// Fluxo: permissão de localização -> termos do Navigation SDK -> sessão
/// de navegação -> destino -> guidance. Qualquer falha cai num estado
/// "indisponível" com a causa e, quando faz sentido, um botão de ação —
/// os botões de registro continuam sempre disponíveis.
class DeliveryRouteScreen extends StatefulWidget {
  const DeliveryRouteScreen({super.key});

  @override
  State<DeliveryRouteScreen> createState() => _DeliveryRouteScreenState();
}

class _DeliveryRouteScreenState extends State<DeliveryRouteScreen> {
  final LocationController locationController = Get.find<LocationController>();
  final RouteController controller = Get.find<RouteController>();
  final OccurrenceController occurrenceController =
      Get.find<OccurrenceController>();

  // Só libera a saída da entrega depois de um desfecho registrado (entregue
  // ou não). Começa bloqueado até a primeira checagem assíncrona terminar.
  bool _canLeave = false;

  NavigationState _navigation = const NavigationState.preparing();
  bool _sessionReady = false;

  StreamSubscription<OnArrivalEvent>? _arrivalSub;
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>? _remainingSub;
  StreamSubscription<void>? _reroutingSub;

  bool get _hasDestination {
    final d = controller.selectedDelivery;
    return d != null && (d.destinationLat != 0.0 || d.destinationLng != 0.0);
  }

  LatLng? get _destination {
    final d = controller.selectedDelivery;
    if (!_hasDestination) return null;
    return LatLng(latitude: d!.destinationLat, longitude: d.destinationLng);
  }

  @override
  void initState() {
    super.initState();
    _refreshOutcomeStatus();
    _startNavigation();
  }

  @override
  void dispose() {
    _arrivalSub?.cancel();
    _remainingSub?.cancel();
    _reroutingSub?.cancel();
    // Encerra guidance, notificação e sessão ao sair da parada.
    if (_sessionReady) {
      GoogleMapsNavigator.cleanup().catchError((_) {});
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Navegação
  // ---------------------------------------------------------------------

  void _setNavigation(NavigationState state) {
    if (mounted) setState(() => _navigation = state);
  }

  void _unavailable(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _setNavigation(
      NavigationState(
        phase: NavPhase.unavailable,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  Future<void> _startNavigation() async {
    final delivery = controller.selectedDelivery;
    if (delivery == null) return;

    if (!_hasDestination) {
      _unavailable(
        'Esta parada não tem coordenadas. Siga pelo endereço informado.',
      );
      return;
    }

    _setNavigation(const NavigationState.preparing('Verificando localização…'));

    try {
      // 1. Permissão de localização
      if (!await _ensureLocationPermission()) return;

      // 2. Termos de uso do Navigation SDK (só aparece na primeira vez)
      _setNavigation(const NavigationState.preparing('Aguardando os termos…'));
      final accepted = await GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Navegação GoLog',
        'GoLog',
        uiParams: const TermsAndConditionsUIParams(
          backgroundColor: Styles.COLOR_WHITE,
          titleColor: Styles.COLOR_BLACKBLUE,
          mainTextColor: Styles.COLOR_TEXT,
          acceptButtonTextColor: Styles.COLOR_LIGHTGREEN,
          cancelButtonTextColor: Styles.COLOR_TEXT_SECONDARY,
        ),
      );
      if (!accepted) {
        _unavailable(
          'É preciso aceitar os termos do Google para usar a navegação.',
          actionLabel: 'Aceitar',
          onAction: _startNavigation,
        );
        return;
      }

      // 3. Sessão de navegação
      _setNavigation(const NavigationState.preparing());
      if (!await GoogleMapsNavigator.isInitialized()) {
        await GoogleMapsNavigator.initializeNavigationSession(
          notificationOptions: const NavigationNotificationOptions(
            defaultMessage: 'GoLog: navegação ativa',
            resumeAppOnTap: true,
          ),
        );
      }
      _listenNavigationEvents();
      if (mounted) setState(() => _sessionReady = true);

      // 4. Destino + guidance
      await _routeToDestination();
    } catch (e) {
      debugPrint('Erro ao iniciar navegação: $e');
      _unavailable(
        'Não foi possível iniciar a navegação.',
        actionLabel: 'Tentar',
        onAction: _startNavigation,
      );
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _unavailable(
        'Ative a localização do aparelho para navegar.',
        actionLabel: 'Ativar',
        onAction: () async {
          await Geolocator.openLocationSettings();
          _startNavigation();
        },
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _unavailable(
        'Permissão de localização bloqueada. Libere nas configurações.',
        actionLabel: 'Abrir',
        onAction: () async {
          await Geolocator.openAppSettings();
          _startNavigation();
        },
      );
      return false;
    }
    if (permission == LocationPermission.denied) {
      _unavailable(
        'Permita o acesso à localização para navegar.',
        actionLabel: 'Permitir',
        onAction: _startNavigation,
      );
      return false;
    }
    return true;
  }

  // Status que costumam ser passageiros logo após iniciar a sessão (SDK
  // ainda baixando configuração / sem fix de GPS): vale tentar de novo
  // automaticamente antes de mostrar erro ao motorista.
  static const _transientStatuses = {
    NavigationRouteStatus.networkError,
    NavigationRouteStatus.locationUnknown,
    NavigationRouteStatus.locationUnavailable,
  };
  static const int _maxRouteAttempts = 3;

  Future<NavigationRouteStatus> _requestRoute() {
    final delivery = controller.selectedDelivery!;
    return GoogleMapsNavigator.setDestinations(
      Destinations(
        waypoints: [
          NavigationWaypoint.withLatLngTarget(
            title: FormatUtils.orFallback(
              delivery.recipientName,
              FormatUtils.address(delivery.destinationAddress),
            ),
            target: _destination!,
          ),
        ],
        displayOptions: NavigationDisplayOptions(showDestinationMarkers: true),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
          // Dá tempo de o SDK obter a primeira localização antes de
          // desistir com LOCATION_UNKNOWN.
          locationTimeoutMs: 15000,
        ),
      ),
    );
  }

  Future<void> _routeToDestination() async {
    var status = NavigationRouteStatus.unknown;
    for (var attempt = 1; attempt <= _maxRouteAttempts; attempt++) {
      status = await _requestRoute();
      debugPrint(
        '[Navegação] setDestinations tentativa $attempt/$_maxRouteAttempts '
        '-> $status (destino: $_destination)',
      );
      if (status == NavigationRouteStatus.statusOk ||
          !_transientStatuses.contains(status) ||
          attempt == _maxRouteAttempts ||
          !mounted) {
        break;
      }
      _setNavigation(
        NavigationState.preparing(
          'Tentando calcular a rota novamente ($attempt/$_maxRouteAttempts)…',
        ),
      );
      await Future.delayed(Duration(seconds: 2 * attempt));
    }

    if (status != NavigationRouteStatus.statusOk) {
      _unavailable(
        _routeStatusMessage(status),
        actionLabel: 'Tentar',
        onAction: _retryRoute,
      );
      return;
    }

    await GoogleMapsNavigator.startGuidance();
    final current = await GoogleMapsNavigator.getCurrentTimeAndDistance();
    _setNavigation(
      NavigationState(
        phase: NavPhase.navigating,
        remainingSeconds: current.time,
        remainingMeters: current.distance,
      ),
    );
  }

  Future<void> _retryRoute() async {
    _setNavigation(const NavigationState.preparing());
    try {
      await _routeToDestination();
    } catch (e) {
      debugPrint('Erro ao recalcular rota: $e');
      _unavailable(
        'Não foi possível calcular a rota.',
        actionLabel: 'Tentar',
        onAction: _retryRoute,
      );
    }
  }

  void _listenNavigationEvents() {
    _arrivalSub ??= GoogleMapsNavigator.setOnArrivalListener((event) async {
      HapticFeedback.mediumImpact();
      await GoogleMapsNavigator.stopGuidance().catchError((_) {});
      _setNavigation(const NavigationState(phase: NavPhase.arrived));
    });

    _remainingSub ??=
        GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
          (event) {
            if (_navigation.phase != NavPhase.navigating) return;
            _setNavigation(
              NavigationState(
                phase: NavPhase.navigating,
                remainingSeconds: event.remainingTime,
                remainingMeters: event.remainingDistance,
              ),
            );
          },
          remainingTimeThresholdSeconds: 10,
          remainingDistanceThresholdMeters: 20,
        );

    _reroutingSub ??= GoogleMapsNavigator.setOnReroutingListener(() {
      if (_navigation.phase != NavPhase.navigating) return;
      Get.rawSnackbar(
        message: 'Recalculando rota…',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: Styles.RADIUS_M,
        backgroundColor: Styles.COLOR_BLACKBLUE,
      );
    });
  }

  String _routeStatusMessage(NavigationRouteStatus status) {
    final message = switch (status) {
      // O Navigation SDK devolve NETWORK_ERROR também quando o backend
      // recusa a requisição (chave restrita, SDK não habilitado, billing),
      // não só quando falta internet.
      NavigationRouteStatus.networkError =>
        'O serviço de rotas não respondeu. Verifique a internet e tente novamente.',
      NavigationRouteStatus.routeNotFound =>
        'Nenhuma rota encontrada até o destino.',
      NavigationRouteStatus.locationUnavailable ||
      NavigationRouteStatus.locationUnknown =>
        'Aguardando sinal de GPS para calcular a rota.',
      NavigationRouteStatus.apiKeyNotAuthorized =>
        'Chave da API não autorizada para o Navigation SDK.',
      NavigationRouteStatus.quotaExceeded =>
        'Limite de uso da navegação atingido.',
      _ => 'Não foi possível calcular a rota.',
    };
    // Em debug, mostra o código cru do SDK para facilitar o diagnóstico.
    return kDebugMode ? '$message [${status.name}]' : message;
  }

  Future<void> _onViewCreated(GoogleNavigationViewController c) async {
    try {
      // O painel do app já mostra tempo/distância: esconde o rodapé do SDK
      // e reserva espaço para o ícone do motorista não ficar atrás do painel.
      await c.setNavigationFooterEnabled(false);
      await c.setPadding(
        const EdgeInsets.only(bottom: DeliveryRouteView.panelReservedHeight),
      );
      await c.setMyLocationEnabled(true);
    } catch (e) {
      debugPrint('Erro ao configurar mapa de navegação: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Saída / ocorrências
  // ---------------------------------------------------------------------

  Future<void> _refreshOutcomeStatus() async {
    final delivery = controller.selectedDelivery;
    final hasOutcome = delivery == null
        ? true
        : await occurrenceController.hasOutcomeOccurrence(delivery.id);
    if (mounted) setState(() => _canLeave = hasOutcome);
  }

  void _showOutcomeRequiredWarning() {
    Get.snackbar(
      'Ocorrência necessária',
      'Registre a entrega ou uma ocorrência antes de sair desta parada.',
      backgroundColor: Styles.COLOR_WHITE,
      colorText: Styles.COLOR_TEXT,
      icon: const Icon(Icons.info_outline_rounded, color: Styles.COLOR_ORANGE),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
    );
  }

  void _openOccurrence(ActionType action) {
    occurrenceController.startNewOccurrence(action);
    Get.to(
      () => const OccurrenceScreen(),
    )?.then((_) => _refreshOutcomeStatus());
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  Widget _buildMap() {
    if (!_sessionReady) {
      final unavailable = _navigation.phase == NavPhase.unavailable;
      return MapPlaceholder(
        loading: !unavailable,
        icon: Icons.navigation_outlined,
        message: unavailable
            ? 'Navegação indisponível'
            : 'Iniciando navegação…',
      );
    }

    return GoogleMapsNavigationView(
      onViewCreated: _onViewCreated,
      initialNavigationUIEnabledPreference:
          NavigationUIEnabledPreference.automatic,
      initialCameraPosition: CameraPosition(
        target:
            _destination ??
            LatLng(
              latitude: locationController.latitude.value,
              longitude: locationController.longitude.value,
            ),
        zoom: 15,
      ),
      initialZoomControlsEnabled: false,
      initialMapToolbarEnabled: false,
      initialPadding: const EdgeInsets.only(
        bottom: DeliveryRouteView.panelReservedHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showOutcomeRequiredWarning();
      },
      child: Obx(
        () => DeliveryRouteView(
          delivery: controller.selectedDelivery,
          routeCode: controller.selectedTransport?.codeTransport,
          locationError: locationController.errorMessage.value,
          navigation: _navigation,
          map: _buildMap(),
          onBack: () {
            if (_canLeave) {
              Get.back();
            } else {
              _showOutcomeRequiredWarning();
            }
          },
          onRegisterDelivery: () => _openOccurrence(ActionType.signature),
          onRegisterOccurrence: () => _openOccurrence(ActionType.observation),
          onFinishRoute: () => _openOccurrence(ActionType.finish),
        ),
      ),
    );
  }
}

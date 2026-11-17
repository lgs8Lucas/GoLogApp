import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:golog/data/datasource/local/coordinate_sql_service.dart';
import 'package:golog/data/model/coordinate.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/util/log.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    show LatLng;

/// Acompanha a posição do aparelho e grava o trajeto enquanto há uma rota
/// ativa. Só começa depois do login ([start]); se a permissão for negada,
/// tenta de novo quando o app volta ao primeiro plano.
///
/// PENDENTE: a gravação só acontece com o app em primeiro plano. Para
/// gravar com a tela bloqueada no Android é preciso foreground service +
/// ACCESS_BACKGROUND_LOCATION.
class LocationController extends GetxController with WidgetsBindingObserver {
  /// Distância mínima entre pontos gravados. 1 m gerava milhares de
  /// registros (e requisições) por rota sem ganho real de precisão.
  static const int _distanceFilterMeters = 10;

  final RouteController _routeController;
  final CoordinateSqlService _coordinateSqlService;

  LocationController(this._routeController, this._coordinateSqlService);

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  LatLng get truckPosition =>
      LatLng(latitude: latitude.value, longitude: longitude.value);

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _wanted = false;
  bool _starting = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _wanted &&
        _positionStreamSubscription == null) {
      // Ex: o motorista liberou a permissão nas configurações e voltou.
      _checkPermissionAndStartTracking(request: false);
    }
  }

  /// Inicia o acompanhamento (idempotente).
  void start() {
    _wanted = true;
    if (_positionStreamSubscription != null) return;
    _checkPermissionAndStartTracking();
  }

  void stop() {
    _wanted = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _checkPermissionAndStartTracking({bool request = true}) async {
    if (_starting) return;
    _starting = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        isLoading.value = false;
        errorMessage.value =
            'O serviço de localização está desativado no aparelho.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        isLoading.value = false;
        errorMessage.value = 'Permissão de localização negada pelo usuário.';
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        isLoading.value = false;
        errorMessage.value =
            'As permissões de localização foram permanentemente negadas. Ative nas configurações.';
        return;
      }

      if (_wanted && _positionStreamSubscription == null) _startTracking();
    } catch (e) {
      appLog('Erro ao verificar localização: $e');
    } finally {
      _starting = false;
    }
  }

  void _startTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _onPosition,
          onError: (error) {
            errorMessage.value = 'Erro ao obter localização: $error';
          },
        );
  }

  void _onPosition(Position position) {
    latitude.value = position.latitude;
    longitude.value = position.longitude;
    isLoading.value = false;
    errorMessage.value = '';

    final active = _routeController.activeTransport;
    if (active == null) return;

    _coordinateSqlService
        .insertCoordinate(
          Coordinate(
            dateTime: DateTime.now(),
            latitude: position.latitude.toString(),
            longitude: position.longitude.toString(),
            speed: position.speed,
            alert: null,
            data1: null,
            data2: null,
            device: 'GoLogApp',
            equipmentId: active.equipmentId,
            isSynced: false,
          ),
        )
        .catchError((Object e) {
          appLog('Erro ao gravar coordenada: $e');
          return 0;
        });
  }
}

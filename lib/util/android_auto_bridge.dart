import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Ponte entre o app no celular e a tela do GoLog no Android Auto
/// (android/app/src/main/kotlin/br/com/golog/app/auto/GoLogCarScreen.kt).
///
/// O mapa e o turn-by-turn do carro vêm direto da sessão do Navigation SDK;
/// esta ponte só informa a parada atual (para as mensagens do carro) e avisa
/// o app quando o motorista encerra a navegação pelo carro.
///
/// Os eventos só chegam ao carro enquanto a tela dele existe, então o último
/// estado fica guardado e é reenviado sempre que o carro se conecta.
class AndroidAutoBridge {
  AndroidAutoBridge._();

  static final AndroidAutoBridge instance = AndroidAutoBridge._();

  // Nomes dos eventos: mantenha em sincronia com GoLogCarScreen.kt.
  static const _eventDelivery = 'delivery';
  static const _eventArrived = 'arrived';
  static const _eventClear = 'clear';
  static const _eventHostStop = 'hostStopNavigation';

  final _controller = GoogleMapsAutoViewController();
  final _hostStop = StreamController<void>.broadcast();

  bool _listening = false;
  bool _screenAvailable = false;
  String _lastEvent = _eventClear;
  Map<String, Object> _lastData = const {};

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Emite quando o motorista encerra a navegação pelo Android Auto.
  Stream<void> get onHostStopNavigation => _hostStop.stream;

  void _ensureListening() {
    if (_listening || !_supported) return;
    _listening = true;
    try {
      _controller.listenForCustomNavigationAutoEvents((event) {
        if (event.event == _eventHostStop) _hostStop.add(null);
      });
      _controller.listenForAutoScreenAvailibilityChangedEvent((event) {
        _screenAvailable = event.isAvailable;
        if (event.isAvailable) _send(_lastEvent, _lastData);
      });
      _controller
          .isAutoScreenAvailable()
          .then((available) {
            _screenAvailable = available;
            if (available) _send(_lastEvent, _lastData);
          })
          .catchError((_) {});
    } catch (e) {
      debugPrint('[AndroidAuto] Falha ao registrar listeners: $e');
    }
  }

  /// Parada em andamento: mostrada no carro enquanto a rota é calculada.
  void showDelivery({required String title, String? address}) {
    _update(_eventDelivery, {
      'title': title,
      if (address != null && address.isNotEmpty) 'address': address,
    });
  }

  /// Chegou ao destino: o carro pede para registrar a entrega no celular.
  void arrived() => _update(_eventArrived, _lastData);

  /// Saiu da parada: o carro volta para "nenhuma entrega em andamento".
  void clear() => _update(_eventClear, const {});

  void _update(String event, Map<String, Object> data) {
    if (!_supported) return;
    _ensureListening();
    _lastEvent = event;
    _lastData = data;
    if (_screenAvailable) _send(event, data);
  }

  void _send(String event, Map<String, Object> data) {
    _controller.sendCustomNavigationAutoEvent(event, data).catchError((e) {
      debugPrint('[AndroidAuto] Falha ao enviar "$event": $e');
    });
  }
}

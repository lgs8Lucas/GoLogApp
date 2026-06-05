import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// 1. Sua classe utilitária atualizada
class MapUtils {
  static const token = String.fromEnvironment('MAP_API_KEY');

  static Widget getMap({
    required Position centerPosition,
    int height = 350,
    required Position truckPosition,
    List<Position> routePoints = const [],
  }) {
    MapboxOptions.setAccessToken(token);
    return MapboxWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
    );
  }

  // NOVO MÉTODO: Estilo Waze (Inclinado/3D)
  static Widget getDeliveryMap({
    required Position centerPosition,
    int height = 350,
    required Position truckPosition,
    List<Position> routePoints = const [],
    double bearing = 0.0, // Direção da câmera (em graus)
    double pitch = 55.0, // Ângulo de inclinação (estilo Waze)
    double zoom = 16.5, // Um pouco mais perto para sensação 3D
  }) {
    MapboxOptions.setAccessToken(token);
    return MapboxWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
      pitch: pitch,
      bearing: bearing,
      zoom: zoom,
      isDeliveryMode: true, // Flag para renderizar prédios em 3D se desejar
    );
  }
}

// 2. O Widget interno adaptado
class MapboxWidgetAdapter extends StatefulWidget {
  final Position centerPosition;
  final int height;
  final Position truckPosition;
  final List<Position> routePoints;
  final double pitch;
  final double bearing;
  final double zoom;
  final bool isDeliveryMode;

  const MapboxWidgetAdapter({
    super.key,
    required this.centerPosition,
    this.height = 350,
    required this.truckPosition,
    this.routePoints = const [],
    this.pitch = 0.0,
    this.bearing = 0.0,
    this.zoom = 17.0,
    this.isDeliveryMode = false,
  });

  @override
  State<MapboxWidgetAdapter> createState() => _MapboxWidgetAdapterState();
}

class _MapboxWidgetAdapterState extends State<MapboxWidgetAdapter> {
  MapboxMap? _mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _renderMapElements();
  }

  Future<void> _renderMapElements() async {
    if (_mapboxMap == null) return;

    // Se estiver no modo entrega, ativa a camada de prédios em 3D
    if (widget.isDeliveryMode) {
      _enable3dBuildings();
    }

    // SOLUÇÃO: Usar um Círculo Nativo (Garante que vai aparecer algo na tela)
    final circleManager = await _mapboxMap!.annotations
        .createCircleAnnotationManager();
    await circleManager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: widget.truckPosition),
        circleColor: Colors.redAccent.toARGB32(), // Cor do marcador
        circleRadius: 10.0, // Tamanho do círculo
        circleStrokeWidth: 3.0, // Borda do círculo
        circleStrokeColor: Colors.white.toARGB32(), // Cor da borda
      ),
    );

    // Configura a linha da rota
    if (widget.routePoints.isNotEmpty) {
      final polylineManager = await _mapboxMap!.annotations
          .createPolylineAnnotationManager();
      await polylineManager.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: widget.routePoints),
          lineColor: Colors.blueAccent.toARGB32(),
          lineWidth: 6.0,
        ),
      );
    }
  }

  // Opcional: Mostra os prédios saltando em 3D conforme o Waze faz em centros urbanos
  void _enable3dBuildings() async {
    try {
      if (await _mapboxMap!.style.styleLayerExists("building")) {
        // Altera a propriedade da camada nativa de prédios para dar volume (se disponível no estilo)
        await _mapboxMap!.style.setStyleLayerProperty(
          "building",
          "building-extrusion-height",
          ["get", "height"],
        );
      }
    } catch (e) {
      // Ignora silenciosamente se o estilo padrão não tiver a camada configurável
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.toDouble(),
      child: MapWidget(
        key: ValueKey(
          "mapbox_${widget.centerPosition.lat}_${widget.centerPosition.lng}_${widget.pitch}",
        ),
        onMapCreated: _onMapCreated,
        styleUri: MapboxStyles.MAPBOX_STREETS,
        cameraOptions: CameraOptions(
          center: Point(coordinates: widget.centerPosition),
          zoom: widget.zoom,
          pitch: widget.pitch, // Aplica a inclinação da tela
          bearing: widget.bearing, // Aplica a rotação da tela
        ),
      ),
    );
  }
}

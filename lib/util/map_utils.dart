import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// 1. Sua classe utilitária atualizada com stopPoints
class MapUtils {
  static const token = String.fromEnvironment('MAP_API_KEY');

  static Widget getMap({
    required Position centerPosition,
    int height = 350,
    required Position truckPosition,
    List<Position> routePoints = const [],
    List<Position> stopPoints = const [], // <--- ADICIONADO
    zoom = 17.0,
  }) {
    MapboxOptions.setAccessToken(token);
    return MapboxWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
      stopPoints: stopPoints, // <--- ADICIONADO
      zoom: zoom,
    );
  }

  // MÉTODO: Estilo Waze (Inclinado/3D) com stopPoints
  static Widget getDeliveryMap({
    required Position centerPosition,
    int height = 350,
    required Position truckPosition,
    List<Position> routePoints = const [],
    List<Position> stopPoints = const [], // <--- ADICIONADO
    double bearing = 0.0,
    double pitch = 55.0,
    double zoom = 16.5,
  }) {
    MapboxOptions.setAccessToken(token);
    return MapboxWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
      stopPoints: stopPoints, // <--- ADICIONADO
      pitch: pitch,
      bearing: bearing,
      zoom: zoom,
      isDeliveryMode: true,
    );
  }

  static List<Position> getCoordinates(String encodedPolyline) {
    List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
      encodedPolyline,
    );
    return decodedPoints.map((point) => Position(point.longitude, point.latitude)).toList();
  }

  static Map<String, dynamic> getCenterAndZoom(List<Position> positions) {
  if (positions.isEmpty) {
    return {
      'center': Position(0, 0),
      'zoom': 2.0,
    };
  }

  num minLat = positions.first.lat;
  num maxLat = positions.first.lng;
  num minLng = positions.first.lat;
  num maxLng = positions.first.lng;
  
  double sumLat = 0;
  double sumLng = 0;

  for (var pos in positions) {
    if (pos.lat < minLat) minLat = pos.lat;
    if (pos.lat > maxLat) maxLat = pos.lat;
    if (pos.lng < minLng) minLng = pos.lng;
    if (pos.lng > maxLng) maxLng = pos.lng;

    sumLat += pos.lat;
    sumLng += pos.lng;
  }

  // 1. Calcula o Centro Médio
  Position center = Position(sumLng / positions.length, sumLat / positions.length);

  // 2. Calcula o Zoom Ideal baseado no maior Delta
  num latDelta = maxLat - minLat;
  num lngDelta = maxLng - minLng;
  num maxDelta = max(latDelta, lngDelta);

  double zoom = 13.0; // Zoom padrão caso os pontos sejam no mesmo lugar

  if (maxDelta > 0) {
    // Fórmula baseada em logaritmo para a escala do mapa
    zoom = (log(360 / maxDelta) / ln2).floorToDouble();
    
    // Restringe para evitar zooms absurdos
    zoom = zoom.clamp(3.0, 15.0); 
  }

  return {
    'center': center,
    'zoom': zoom,
  };
}
}

// 2. O Widget interno adaptado com suporte a stopPoints
class MapboxWidgetAdapter extends StatefulWidget {
  final Position centerPosition;
  final int height;
  final Position truckPosition;
  final List<Position> routePoints;
  final List<Position> stopPoints; // <--- ADICIONADO
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
    this.stopPoints = const [], // <--- ADICIONADO
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

    if (widget.isDeliveryMode) {
      _enable3dBuildings();
    }

    // Gerenciador de Círculos para os marcadores (Caminhão e Paradas)
    final circleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();

    // 1. Marcador do Caminhão (Vermelho)
    await circleManager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: widget.truckPosition),
        circleColor: Colors.redAccent.toARGB32(),
        circleRadius: 10.0,
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );

    // 2. NOVO: Renderizar os Stop Points (Paradas em Laranja/Amarelo)
    if (widget.stopPoints.isNotEmpty) {
      for (var stopPosition in widget.stopPoints) {
        await circleManager.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: stopPosition),
            circleColor: Colors.orange.toARGB32(), // Cor diferenciada para as paradas
            circleRadius: 8.0, // Um pouco menor que o caminhão
            circleStrokeWidth: 2.5,
            circleStrokeColor: Colors.white.toARGB32(),
          ),
        );
      }
    }

    // Configura a linha da rota
    if (widget.routePoints.isNotEmpty) {
      final polylineManager = await _mapboxMap!.annotations.createPolylineAnnotationManager();
      await polylineManager.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: widget.routePoints),
          lineColor: Colors.blueAccent.toARGB32(),
          lineWidth: 6.0,
        ),
      );
    }
  }

  void _enable3dBuildings() async {
    try {
      if (await _mapboxMap!.style.styleLayerExists("building")) {
        await _mapboxMap!.style.setStyleLayerProperty(
          "building",
          "building-extrusion-height",
          ["get", "height"],
        );
      }
    } catch (e) {
      // Ignora silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.toDouble(),
      child: MapWidget(
        key: ValueKey(
          "mapbox_${widget.centerPosition.lat}_${widget.centerPosition.lng}_${widget.pitch}_${widget.stopPoints.length}",
        ),
        onMapCreated: _onMapCreated,
        styleUri: MapboxStyles.MAPBOX_STREETS,
        cameraOptions: CameraOptions(
          center: Point(coordinates: widget.centerPosition),
          zoom: widget.zoom,
          pitch: widget.pitch,
          bearing: widget.bearing,
        ),
      ),
    );
  }
}
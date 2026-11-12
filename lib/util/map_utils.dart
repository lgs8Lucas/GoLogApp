import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:gologapp/util/styles.dart';

/// Utilitários de mapa. Usa o `GoogleMapsMapView` do google_navigation_flutter
/// (e não o google_maps_flutter): o Navigation SDK já embute o Maps SDK e os
/// dois plugins juntos geram classes duplicadas no build Android.
class MapUtils {
  /// Mapa de visão geral da rota (sem navegação), com a linha planejada e
  /// os marcadores das paradas.
  static Widget getMap({
    required LatLng centerPosition,
    int height = 350,
    List<LatLng> routePoints = const [],
    List<LatLng> stopPoints = const [],
    double zoom = 17.0,
  }) {
    return RouteOverviewMap(
      centerPosition: centerPosition,
      height: height,
      routePoints: routePoints,
      stopPoints: stopPoints,
      zoom: zoom,
    );
  }

  static List<LatLng> getCoordinates(String encodedPolyline) {
    List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
      encodedPolyline,
    );
    return decodedPoints
        .map((p) => LatLng(latitude: p.latitude, longitude: p.longitude))
        .toList();
  }

  static Map<String, dynamic> getCenterAndZoom(List<LatLng> positions) {
    if (positions.isEmpty) {
      return {'center': const LatLng(latitude: 0, longitude: 0), 'zoom': 2.0};
    }

    num minLat = positions.first.latitude;
    num maxLat = positions.first.latitude;
    num minLng = positions.first.longitude;
    num maxLng = positions.first.longitude;

    double sumLat = 0;
    double sumLng = 0;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;

      sumLat += pos.latitude;
      sumLng += pos.longitude;
    }

    LatLng center = LatLng(
      latitude: sumLat / positions.length,
      longitude: sumLng / positions.length,
    );

    num latDelta = maxLat - minLat;
    num lngDelta = maxLng - minLng;
    num maxDelta = max(latDelta, lngDelta);

    double zoom = 13.0;

    if (maxDelta > 0) {
      zoom = (log(360 / maxDelta) / ln2).floorToDouble();
      zoom = zoom.clamp(3.0, 15.0);
    }

    return {'center': center, 'zoom': zoom};
  }
}

class RouteOverviewMap extends StatefulWidget {
  final LatLng centerPosition;
  final int height;
  final List<LatLng> routePoints;
  final List<LatLng> stopPoints;
  final double zoom;

  const RouteOverviewMap({
    super.key,
    required this.centerPosition,
    this.height = 350,
    this.routePoints = const [],
    this.stopPoints = const [],
    this.zoom = 17.0,
  });

  @override
  State<RouteOverviewMap> createState() => _RouteOverviewMapState();
}

class _RouteOverviewMapState extends State<RouteOverviewMap> {
  GoogleMapViewController? _controller;

  Future<void> _onViewCreated(GoogleMapViewController controller) async {
    _controller = controller;
    try {
      // Ponto azul nativo, alimentado direto pelo GPS do sistema.
      await controller.setMyLocationEnabled(true);
    } catch (_) {
      // Sem permissão de localização: o mapa segue funcionando sem o ponto.
    }
    await _drawOverlays();
  }

  @override
  void didUpdateWidget(RouteOverviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pointsChanged =
        !_sameList(oldWidget.stopPoints, widget.stopPoints) ||
        !_sameList(oldWidget.routePoints, widget.routePoints);
    if (pointsChanged) _drawOverlays();

    if (oldWidget.centerPosition != widget.centerPosition) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.centerPosition, widget.zoom),
      );
    }
  }

  bool _sameList(List<LatLng> a, List<LatLng> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _drawOverlays() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.clearMarkers();
      await c.clearPolylines();
      if (widget.routePoints.isNotEmpty) {
        await c.addPolylines([
          PolylineOptions(
            points: widget.routePoints,
            strokeColor: Styles.COLOR_BLUE,
            strokeWidth: 6,
          ),
        ]);
      }
      if (widget.stopPoints.isNotEmpty) {
        await c.addMarkers([
          for (var i = 0; i < widget.stopPoints.length; i++)
            MarkerOptions(position: widget.stopPoints[i], zIndex: i.toDouble()),
        ]);
      }
    } catch (e) {
      debugPrint('Erro ao desenhar a rota no mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.toDouble(),
      child: GoogleMapsMapView(
        onViewCreated: _onViewCreated,
        initialCameraPosition: CameraPosition(
          target: widget.centerPosition,
          zoom: widget.zoom,
        ),
        initialZoomControlsEnabled: false,
        initialMapToolbarEnabled: false,
      ),
    );
  }
}

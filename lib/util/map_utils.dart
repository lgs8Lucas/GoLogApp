import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  static Widget getMap({
    required LatLng centerPosition,
    int height = 350,
    required LatLng truckPosition,
    List<LatLng> routePoints = const [],
    List<LatLng> stopPoints = const [],
    double zoom = 17.0,
  }) {
    return GoogleMapWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
      stopPoints: stopPoints,
      zoom: zoom,
    );
  }

  static Widget getDeliveryMap({
    required LatLng centerPosition,
    int height = 350,
    required LatLng truckPosition,
    List<LatLng> routePoints = const [],
    List<LatLng> stopPoints = const [],
    double bearing = 0.0,
    double pitch = 55.0,
    double zoom = 16.5,
  }) {
    return GoogleMapWidgetAdapter(
      centerPosition: centerPosition,
      height: height,
      truckPosition: truckPosition,
      routePoints: routePoints,
      stopPoints: stopPoints,
      pitch: pitch,
      bearing: bearing,
      zoom: zoom,
      isDeliveryMode: true,
    );
  }

  static List<LatLng> getCoordinates(String encodedPolyline) {
    List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
      encodedPolyline,
    );
    return decodedPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  static Map<String, dynamic> getCenterAndZoom(List<LatLng> positions) {
    if (positions.isEmpty) {
      return {
        'center': const LatLng(0, 0),
        'zoom': 2.0,
      };
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
      sumLat / positions.length,
      sumLng / positions.length,
    );

    num latDelta = maxLat - minLat;
    num lngDelta = maxLng - minLng;
    num maxDelta = max(latDelta, lngDelta);

    double zoom = 13.0;

    if (maxDelta > 0) {
      zoom = (log(360 / maxDelta) / ln2).floorToDouble();
      zoom = zoom.clamp(3.0, 15.0);
    }

    return {
      'center': center,
      'zoom': zoom,
    };
  }
}

class GoogleMapWidgetAdapter extends StatefulWidget {
  final LatLng centerPosition;
  final int height;
  final LatLng truckPosition;
  final List<LatLng> routePoints;
  final List<LatLng> stopPoints;
  final double pitch;
  final double bearing;
  final double zoom;
  final bool isDeliveryMode;

  const GoogleMapWidgetAdapter({
    super.key,
    required this.centerPosition,
    this.height = 350,
    required this.truckPosition,
    this.routePoints = const [],
    this.stopPoints = const [],
    this.pitch = 0.0,
    this.bearing = 0.0,
    this.zoom = 17.0,
    this.isDeliveryMode = false,
  });

  @override
  State<GoogleMapWidgetAdapter> createState() =>
      _GoogleMapWidgetAdapterState();
}

class _GoogleMapWidgetAdapterState extends State<GoogleMapWidgetAdapter> {
  GoogleMapController? _controller;
  late Set<Marker> _markers;
  late Set<Polyline> _polylines;

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkers();
    _polylines = _buildPolylines();
  }

  @override
  void didUpdateWidget(GoogleMapWidgetAdapter oldWidget) {
    super.didUpdateWidget(oldWidget);

    final pointsChanged = oldWidget.stopPoints != widget.stopPoints ||
        oldWidget.routePoints != widget.routePoints ||
        oldWidget.truckPosition != widget.truckPosition;
    if (pointsChanged) {
      setState(() {
        _markers = _buildMarkers();
        _polylines = _buildPolylines();
      });
    }

    if (oldWidget.truckPosition != widget.truckPosition ||
        oldWidget.centerPosition != widget.centerPosition) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.centerPosition,
            zoom: widget.zoom,
            tilt: widget.pitch,
            bearing: widget.bearing,
          ),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('truck'),
        position: widget.truckPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndexInt: 1,
      ),
    };

    for (var i = 0; i < widget.stopPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: widget.stopPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routePoints,
        color: Colors.blueAccent,
        width: 6,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.toDouble(),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.centerPosition,
          zoom: widget.zoom,
          tilt: widget.pitch,
          bearing: widget.bearing,
        ),
        onMapCreated: (controller) => _controller = controller,
        markers: _markers,
        polylines: _polylines,
        buildingsEnabled: widget.isDeliveryMode,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}

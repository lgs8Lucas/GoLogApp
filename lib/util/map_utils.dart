import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapUtils {
  static const key = String.fromEnvironment('MAP_API_KEY');

  static Widget getMap({
    required LatLng centerPosition,
    int height = 350,
    required LatLng truckPosition,
    List<LatLng> routePoints = const [],
  }) {
    return SizedBox(
      height: height.toDouble(),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: centerPosition,
          minZoom: 5,
          maxZoom: 25,
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {'accessToken': key, 'id': 'mapbox/streets-v12'},
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: Colors.blueAccent,
                  strokeWidth: 5,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: truckPosition,
                child: const Icon(
                  Icons.fire_truck_rounded,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<Widget> getRouteMap({
    required LatLng centerPosition,
    required LatLng truckPosition,
    int height = 350,
  }) async {
    const url =
        'https://router.project-osrm.org/route/v1/driving/-47.3846,-22.3572;-47.3732,-22.3705?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        final routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
        return getMap(
          centerPosition: centerPosition,
          truckPosition: truckPosition,
          routePoints: routePoints,
          height: height,
        );
      }
    } catch (e) {
      debugPrint("Erro na GoLogAPI: $e");
    }
    return getMap(
      centerPosition: centerPosition,
      truckPosition: truckPosition,
      height: height,
    );
  }
}

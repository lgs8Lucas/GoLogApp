import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double height;

  const MapWidget({super.key, required this.center, this.height = 350});

  @override
  Widget build(BuildContext context) {
    // Rota fixa para teste na GoLogApp
    final List<LatLng> routePoints = [
      LatLng(-22.3572, -47.3846),
      LatLng(-22.3512, -47.3789),
      LatLng(-22.3486, -47.3621),
      LatLng(-22.3526, -47.3685),
      LatLng(-22.3654, -47.3719),
      LatLng(-22.3705, -47.3732),
      LatLng(-22.3572, -47.3846),
    ];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 14.5),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.jonathan.gologapp',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  color: Colors.blueAccent,
                  strokeWidth: 4.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

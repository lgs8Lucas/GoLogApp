import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gologapp/util/styles.dart';
import 'package:http/http.dart' as http;

class MapWidget extends StatefulWidget {
  final LatLng center;
  final double height;
  const MapWidget({super.key, required this.center, this.height = 350});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  List<LatLng> routePoints = [];
  LatLng? vehicleLocation;

  @override
  void initState() {
    super.initState();
    // ESSA LINHA É O MOTOR QUE LIGA TUDO:
    _loadRouteAndStartSim();
  }

  Future<void> _loadRouteAndStartSim() async {
    const url =
        'https://router.project-osrm.org/route/v1/driving/-47.3846,-22.3572;-47.3732,-22.3705?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          if (routePoints.isNotEmpty) {
            vehicleLocation =
                routePoints[0]; // Camião começa no primeiro ponto da linha azul
          }
        });
      }
    } catch (e) {
      debugPrint("Erro na GoLogAPI: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: widget.height,
      child: FlutterMap(
        options: MapOptions(initialCenter: widget.center, initialZoom: 14.5),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
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
              // DESTINO (Último ponto da lista)
              if (routePoints.isNotEmpty)
                Marker(
                  point: routePoints.last,
                  child: const Icon(
                    Icons.location_on,
                    color: Styles.COLOR_RED,
                    size: 35,
                  ),
                ),
              // INICIO (primeiro ponto da lista)
              if (routePoints.isNotEmpty)
                Marker(
                  point: routePoints.first,
                  child: const Icon(
                    Icons.local_shipping,
                    color: Styles.COLOR_BLACKBLUE,
                    size: 30,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

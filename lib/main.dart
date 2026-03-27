import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GuidyApp());
}

class GuidyApp extends StatelessWidget {
  const GuidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guidy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> routePoints = [];
  bool isLoading = false;
  String travelTime = "";

  // Connects to your Python FastAPI server
  Future<void> fetchRoute() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 10.0.2.2 is the Android Emulator's secret IP to reach your laptop's localhost
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/route?start=Opera&end=Al%20Shohadaa'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<LatLng> newPoints = [];
          for (var station in data['path']) {
            newPoints.add(LatLng(station['lat'], station['lon']));
          }
          setState(() {
            routePoints = newPoints;
            travelTime = "${data['total_time_minutes']} min";
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(travelTime.isEmpty ? 'Guidy - Cairo Map' : 'ETA: $travelTime'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(30.0444, 31.2357), // Sadat Station Area
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.guidy.guidyApp',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 5.0,
                color: Colors.blueAccent,
              ),
            ],
          ),
          MarkerLayer(
            markers: routePoints.map((point) => Marker(
              point: point,
              width: 15,
              height: 15,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            )).toList(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchRoute,
        icon: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.directions_transit),
        label: const Text("Find Route"),
      ),
    );
  }
}
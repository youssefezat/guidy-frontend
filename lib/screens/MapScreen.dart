import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> pathData;
  
  const MapScreen({super.key, required this.pathData});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> _routePoints = [];
  Color _routeColor = Colors.blueAccent;
  
  // Live Tracking Variables
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _parsePathData();
    _startLiveTracking();
  }

  void _parsePathData() {
    try {
      if (widget.pathData['path'] != null) {
        _routePoints = (widget.pathData['path'] as List)
            .map((p) => LatLng(p['lat'], p['lon']))
            .toList();
      }
      if (widget.pathData['color'] != null) {
        _routeColor = Color(int.parse(widget.pathData['color'].replaceFirst('#', 'ff'), radix: 16));
      }
    } catch (e) {
      debugPrint("Error parsing path data: $e");
    }
  }

  Future<void> _startLiveTracking() async {
    // 1. Double check permissions just in case
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Fetch the immediate location first so the user doesn't have to wait
    try {
      Position initPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(initPos.latitude, initPos.longitude);
        });
      }
    } catch (e) {
      debugPrint("Could not get initial position.");
    }

    // 3. Open the stream! This listens continuously in the background
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Only update the UI if the user moves at least 5 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    // CRITICAL: We must close the stream when the user leaves the screen 
    // to prevent memory leaks and battery drain!
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Navigation"),
        backgroundColor: const Color(0xFF6DA4C2),
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _routePoints.isNotEmpty ? _routePoints.first : const LatLng(30.0444, 31.2357),
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.guidy.guidy_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 6.0,
                color: _routeColor,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              // Start and End Pins
              if (_routePoints.isNotEmpty) ...[
                Marker(point: _routePoints.first, width: 20, height: 20, child: const Icon(Icons.circle, color: Colors.green, size: 20)),
                Marker(point: _routePoints.last, width: 30, height: 30, child: const Icon(Icons.location_on, color: Colors.red, size: 30)),
              ],
              
              // LIVE USER LOCATION DOT
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.3), // Creates a "pulsing" halo effect
                    ),
                    child: const Center(
                      child: Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      // Recenter Camera Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6DA4C2),
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
        onPressed: () {
          if (_currentLocation != null) {
            // Snaps the camera back to the user's live dot at a zoomed-in level
            _mapController.move(_currentLocation!, 16.0); 
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching location...")));
          }
        },
      ),
    );
  }
}
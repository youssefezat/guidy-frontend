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
  // NEW: We now hold a list of multiple Polylines, one for each color segment
  List<Polyline> _routePolylines = []; 
  List<LatLng> _allPoints = []; // Used to center the camera on load
  List<LatLng> _stationMarkers = []; 
  Color _mainRouteColor = Colors.blueAccent;
  List<dynamic> _instructions = [];
  
  final ValueNotifier<LatLng?> _currentLocation = ValueNotifier(null);
  final ValueNotifier<String> _distanceToNextStop = ValueNotifier("Calculating...");
  
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _parsePathData();
    _startLiveTracking();
  }

  void _parsePathData() {
    try {
      // THE FIX: Parse the new multi-colored segments
      if (widget.pathData['segments'] != null) {
        for (var segment in widget.pathData['segments']) {
          Color segColor = Color(int.parse(segment['color'].replaceFirst('#', 'ff'), radix: 16));
          List<LatLng> pts = (segment['points'] as List).map((p) => LatLng(p['lat'], p['lon'])).toList();
          
          _allPoints.addAll(pts);
          _routePolylines.add(
            Polyline(points: pts, strokeWidth: 8.0, color: segColor)
          );
        }
      }

      if (widget.pathData['station_markers'] != null) {
        _stationMarkers = (widget.pathData['station_markers'] as List)
            .map((p) => LatLng(p['lat'], p['lon']))
            .toList();
      } else {
        _stationMarkers = _allPoints; 
      }

      if (widget.pathData['color'] != null) {
        _mainRouteColor = Color(int.parse(widget.pathData['color'].replaceFirst('#', 'ff'), radix: 16));
      }
      if (widget.pathData['instructions'] != null) {
        _instructions = widget.pathData['instructions'];
      }
    } catch (e) {
      debugPrint("Error parsing path data: $e");
    }
  }

  Future<void> _startLiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, 
        distanceFilter: 1, 
      ),
    ).listen((Position position) {
      if (mounted) {
        _currentLocation.value = LatLng(position.latitude, position.longitude);
        _checkIfApproachingNextStep();
      }
    });
  }

  void _checkIfApproachingNextStep() {
    if (_currentLocation.value == null || _instructions.isEmpty || _currentStepIndex >= _instructions.length - 1) {
      if (_currentStepIndex >= _instructions.length - 1) {
        _distanceToNextStop.value = "You have arrived!";
      }
      return;
    }

    var nextStep = _instructions[_currentStepIndex + 1];
    LatLng targetLocation = LatLng(nextStep['lat'], nextStep['lon']);

    double distance = const Distance().as(LengthUnit.Meter, _currentLocation.value!, targetLocation);
    
    if (distance > 1000) {
      _distanceToNextStop.value = "${(distance / 1000).toStringAsFixed(2)} km to ${nextStep['station']}";
    } else {
      _distanceToNextStop.value = "${distance.toInt()} m to ${nextStep['station']}";
    }

    if (distance < 150) {
      _distanceToNextStop.value = "Arriving at ${nextStep['station']}...";
      
      setState(() {
        _currentStepIndex++;
      });
      _pageController.animateToPage(
        _currentStepIndex, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeInOut
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pageController.dispose();
    _currentLocation.dispose();
    _distanceToNextStop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transit Navigation"),
        backgroundColor: _mainRouteColor, // AppBar stays the color of your starting line
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _allPoints.isNotEmpty ? _allPoints.first : const LatLng(30.0444, 31.2357),
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.guidy.guidy_app',
              ),
              // Draw the dynamic, multi-colored lines!
              PolylineLayer(
                polylines: _routePolylines,
              ),
              MarkerLayer(
                markers: [
                  ..._stationMarkers.map((point) => Marker(
                    point: point, 
                    width: 15, 
                    height: 15, 
                    child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 3)))
                  )),
                ],
              ),
              ValueListenableBuilder<LatLng?>(
                valueListenable: _currentLocation,
                builder: (context, location, child) {
                  if (location == null) return const SizedBox.shrink();
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.3)),
                          child: const Center(child: Icon(Icons.my_location, color: Colors.blueAccent, size: 28)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          if (_instructions.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 80, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _distanceToNextStop,
                        builder: (context, distanceText, child) {
                          return Text(
                            distanceText,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_instructions.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _instructions.length,
                onPageChanged: (index) {
                  setState(() => _currentStepIndex = index);
                  _mapController.move(LatLng(_instructions[index]['lat'], _instructions[index]['lon']), 15.0);
                },
                itemBuilder: (context, index) {
                  var step = _instructions[index];
                  bool isTransfer = step['title'].contains("Transfer");
                  bool isArrive = step['title'].contains("Arrive");

                  return Card(
                    elevation: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: isTransfer ? Colors.orange : (isArrive ? Colors.green : _mainRouteColor), width: 8)),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            isTransfer ? Icons.directions_walk : (isArrive ? Icons.flag : Icons.directions_subway),
                            size: 40, 
                            color: isTransfer ? Colors.orange : (isArrive ? Colors.green : _mainRouteColor)
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(step['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(step['subtitle'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: () {
                if (_currentLocation.value != null) _mapController.move(_currentLocation.value!, 16.0);
              },
            ),
          )
        ],
      ),
    );
  }
}
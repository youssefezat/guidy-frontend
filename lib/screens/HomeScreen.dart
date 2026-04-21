import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'RouteOptionsScreen.dart';
import 'ReportScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  final List<String> _cairoLocations = [
    "Opera", "Sadat", "Attaba", "Al Shohadaa", "Dokki", "Helwan"
  ];

  // We use these to calculate the closest station to your physical GPS
  final Map<String, LatLng> _stationCoords = {
    "Opera": const LatLng(30.0416, 31.2238),
    "Sadat": const LatLng(30.0444, 31.2357),
    "Attaba": const LatLng(30.0531, 31.2475),
    "Al Shohadaa": const LatLng(30.0611, 31.2464),
    "Dokki": const LatLng(30.0384, 31.2117),
    "Helwan": const LatLng(29.8488, 31.3341),
  };

  final List<Map<String, String>> _recentSearches = [
    {"from": "Dokki", "to": "Helwan", "time": "2 hours ago"},
    {"from": "Opera", "to": "Attaba", "time": "1 day ago"},
    {"from": "Sadat", "to": "Al Shohadaa", "time": "2 days ago"},
  ];

  final Map<String, String> _savedLocations = {
    "Home": "Not set",
    "Work": "Not set",
    "Saved": "Not set"
  };

  bool _isFetchingLocation = false;

  Future<void> _getCurrentLocation(TextEditingController controller) async {
    setState(() => _isFetchingLocation = true);
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isFetchingLocation = false);
      _showErrorSnackBar("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isFetchingLocation = false);
        _showErrorSnackBar("Location permissions are denied.");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng userPos = LatLng(position.latitude, position.longitude);
      
      // Find the nearest station to the user's GPS
      String nearestStation = "Dokki"; // Default fallback
      double minDistance = double.infinity;
      const Distance distanceCalculator = Distance();

      _stationCoords.forEach((stationName, stationLatLng) {
        final double dist = distanceCalculator.as(LengthUnit.Meter, userPos, stationLatLng);
        if (dist < minDistance) {
          minDistance = dist;
          nearestStation = stationName;
        }
      });

      setState(() {
        controller.text = nearestStation;
        _isFetchingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nearest station found: $nearestStation"), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isFetchingLocation = false);
      _showErrorSnackBar("Failed to get location.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSaveLocationDialog(String label) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Set $label Location", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text("Use Current Location"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _savedLocations[label] = "Dokki"); // Example save
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label saved!"), backgroundColor: Colors.green));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.orange),
                title: const Text("Choose on Map"),
                subtitle: const Text("Drag and drop a pin"),
                onTap: () async {
                  Navigator.pop(context);
                  final selectedLocation = await Navigator.push(context, MaterialPageRoute(builder: (context) => MapSelectionScreen(label: label)));
                  if (selectedLocation != null) {
                    setState(() => _savedLocations[label] = "Map Selection");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label saved!"), backgroundColor: Colors.green));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Guidy", style: TextStyle(color: Color(0xFF6DA4C2), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD4A373)),
            onPressed: () => Navigator.pushNamed(context, '/report'),
          ),
          IconButton(icon: const Icon(Icons.menu, color: Colors.grey), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Plan Your Journey", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildAutocompleteField(hint: "Starting point", dotColor: Colors.blue, controller: _startController, showGpsButton: true),
                    const SizedBox(height: 15),
                    _buildAutocompleteField(hint: "Destination", dotColor: Colors.orange, controller: _endController, showGpsButton: false),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_startController.text.isEmpty || _endController.text.isEmpty) {
                            _showErrorSnackBar("Please enter both locations.");
                            return;
                          }
                          // Navigating and passing the user's selected stations!
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RouteOptionsScreen(
                            start: _startController.text, 
                            end: _endController.text
                          )));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DA4C2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Find Routes", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text("QUICK ACTIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(Icons.home_outlined, "Home"),
                        _buildQuickAction(Icons.work_outline, "Work"),
                        _buildQuickAction(Icons.location_on_outlined, "Saved"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: _recentSearches.map((search) {
                  return Column(
                    children: [
                      _buildRecentSearch(search["from"]!, search["to"]!, search["time"]!),
                      if (search != _recentSearches.last) const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({required String hint, required Color dotColor, required TextEditingController controller, required bool showGpsButton}) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return _cairoLocations.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) => controller.text = selection,
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        if (fieldController.text != controller.text) fieldController.text = controller.text;
        fieldController.addListener(() => controller.text = fieldController.text);
        return TextField(
          controller: fieldController, focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint, prefixIcon: Icon(Icons.circle, color: dotColor, size: 16),
            suffixIcon: showGpsButton
                ? IconButton(
                    icon: _isFetchingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: () => _getCurrentLocation(controller),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    bool isSet = _savedLocations[label] != "Not set";
    return GestureDetector(
      onTap: () {
        if (isSet) {
          _endController.text = _savedLocations[label]!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Routing to $label...")));
        } else {
          _showSaveLocationDialog(label);
        }
      },
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: isSet ? Colors.blue[50] : Colors.grey[100], child: Icon(icon, color: isSet ? Colors.blue : Colors.grey[700])),
          const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRecentSearch(String from, String to, String time) {
    return InkWell(
      onTap: () {
        setState(() { _startController.text = from; _endController.text = to; });
        Navigator.push(context, MaterialPageRoute(builder: (context) => RouteOptionsScreen(start: from, end: to)));
      },
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.access_time, color: Colors.blue, size: 20)),
        title: Text("$from → $to", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(time, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}

class MapSelectionScreen extends StatefulWidget {
  final String label;
  const MapSelectionScreen({super.key, required this.label});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  LatLng _centerPosition = const LatLng(30.0444, 31.2357);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set ${widget.label} Location"), backgroundColor: const Color(0xFF6DA4C2), foregroundColor: Colors.white),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPosition, initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) { if (position.center != null) _centerPosition = position.center!; },
            ),
            children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.guidy.guidy_app')],
          ),
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 40.0), child: Icon(Icons.location_on, size: 50, color: Colors.red))),
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Card(
              elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Drag the map to pinpoint your location", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DA4C2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () => Navigator.pop(context, _centerPosition),
                        child: const Text("Confirm Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
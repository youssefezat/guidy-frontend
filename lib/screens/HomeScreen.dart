import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'RouteOptionsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();

  String? _homeLocation;
  String? _workLocation;
  List<String> _savedLocations = [];
  List<Map<String, String>> _recentSearches = [];

  // THE COMPLETE METRO LIST
  final List<String> _availableStations = [
    // Line 1
    "New El-Marg", "El-Marg", "Ain Shams", "Saray El-Qobba", "Ghamra", 
    "Al Shohadaa", "Orabi", "Nasser", "Sadat", "Saad Zaghloul", 
    "Al-Sayeda Zeinab", "Mar Girgis", "Maadi", "Tora El-Balad", 
    "Helwan University", "Helwan",
    // Line 2
    "Shubra El-Kheima", "St. Teresa", "Massara", "Attaba", "Mohamed Naguib", 
    "Opera", "Dokki", "El Bohoth", "Cairo University", "Giza", "El Mounib",
    // Line 3
    "Adly Mansour", "El-Nozha", "Heliopolis", "Stadium (Nasr City)", 
    "Fair Zone", "Abbasiya", "Maspero", "Safaa Hegazy (Zamalek)", 
    "Kit Kat", "Imbaba"
  ];

  // Coordinates [Latitude, Longitude] for GPS nearest station finder
  final Map<String, List<double>> _stationCoords = {
    "New El-Marg": [30.1500, 31.3360],
    "El-Marg": [30.1430, 31.3340],
    "Ain Shams": [30.1330, 31.3250],
    "Saray El-Qobba": [30.0980, 31.3090],
    "Ghamra": [30.0670, 31.2720],
    "Al Shohadaa": [30.0611, 31.2464],
    "Orabi": [30.0570, 31.2420],
    "Nasser": [30.0524, 31.2398],
    "Sadat": [30.0444, 31.2357],
    "Saad Zaghloul": [30.0350, 31.2370],
    "Al-Sayeda Zeinab": [30.0300, 31.2360],
    "Mar Girgis": [30.0060, 31.2300],
    "Maadi": [29.9602, 31.2585],
    "Tora El-Balad": [29.9370, 31.2750],
    "Helwan University": [29.8650, 31.3190],
    "Helwan": [29.8488, 31.3341],
    "Shubra El-Kheima": [30.1220, 31.2440],
    "St. Teresa": [30.0920, 31.2460],
    "Massara": [30.0710, 31.2460],
    "Attaba": [30.0531, 31.2475],
    "Mohamed Naguib": [30.0450, 31.2430],
    "Opera": [30.0416, 31.2238],
    "Dokki": [30.0384, 31.2117],
    "El Bohoth": [30.0360, 31.2010],
    "Cairo University": [30.0276, 31.2089],
    "Giza": [30.0130, 31.2080],
    "El Mounib": [29.9810, 31.2110],
    "Adly Mansour": [30.1460, 31.4200],
    "El-Nozha": [30.1280, 31.3500],
    "Heliopolis": [30.0911, 31.3256],
    "Stadium (Nasr City)": [30.0736, 31.3142],
    "Fair Zone": [30.0710, 31.3020],
    "Abbasiya": [30.0650, 31.2820],
    "Maspero": [30.0540, 31.2320],
    "Safaa Hegazy (Zamalek)": [30.0626, 31.2217],
    "Kit Kat": [30.0680, 31.2110],
    "Imbaba": [30.0820, 31.2050],
  };

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  Future<void> _findNearestStation() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Finding nearest Metro station...")));

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      String nearestStation = _availableStations.first;
      double minDistance = double.infinity;

      _stationCoords.forEach((stationName, coords) {
        double lat = coords[0];
        double lon = coords[1];
        double distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lon);
        
        if (distance < minDistance) {
          minDistance = distance;
          nearestStation = stationName;
        }
      });

      setState(() {
        _startController.text = nearestStation;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not get GPS location.")));
    }
  }

  void _performSearch(String start, String end) {
    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both start and end stations.")));
      return;
    }

    setState(() {
      _recentSearches.removeWhere((route) => route['start'] == start && route['end'] == end);
      _recentSearches.insert(0, {'start': start, 'end': end});
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RouteOptionsScreen(start: start, end: end)),
    );
  }

  void _showSetLocationDialog(String title, Function(String) onSave) {
    String? selectedStation = _availableStations.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: DropdownButtonFormField<String>(
                value: selectedStation,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F8),
                ),
                items: _availableStations.map((station) {
                  return DropdownMenuItem(value: station, child: Text(station));
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedStation = val),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DA4C2)),
                  onPressed: () {
                    onSave(selectedStation!);
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _openSavedLocationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Saved Stations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  if (_savedLocations.isEmpty)
                    const Text("No saved stations yet.", style: TextStyle(color: Colors.grey)),
                  
                  ..._savedLocations.map((loc) => ListTile(
                    leading: const Icon(Icons.directions_subway, color: Color(0xFFD4A373)),
                    title: Text(loc, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => _savedLocations.remove(loc));
                        setSheetState(() {}); 
                      },
                    ),
                    onTap: () {
                      _endController.text = loc;
                      Navigator.pop(context);
                    },
                  )),
                  
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DA4C2),
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Add New Station", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        _showSetLocationDialog("Add Saved Station", (val) {
                          if (!_savedLocations.contains(val)) {
                            setState(() => _savedLocations.add(val));
                          }
                        });
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Widget prefixIcon,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _availableStations.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
        focusNode.unfocus(); 
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            hintText: hintText,
            border: InputBorder.none,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 70, 
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Guidy Metro", style: TextStyle(color: Color(0xFF6DA4C2), fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            }, 
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _buildAutocompleteField(
                  controller: _startController,
                  focusNode: _startFocusNode,
                  hintText: "Start Station (e.g. Opera)",
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: _findNearestStation,
                  ),
                ),
                const Divider(),
                _buildAutocompleteField(
                  controller: _endController,
                  focusNode: _endFocusNode,
                  hintText: "Destination (e.g. Dokki)",
                  prefixIcon: const Icon(Icons.directions_subway, color: Colors.red),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DA4C2), padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _performSearch(_startController.text.trim(), _endController.text.trim()),
                    child: const Text("Find Metro Route", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),

          const Text("QUICK ACTIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                icon: Icons.home, 
                label: _homeLocation ?? "Set Home", 
                isSet: _homeLocation != null, // Passes the state to the widget
                onTap: () {
                  if (_homeLocation == null) {
                    _showSetLocationDialog("Set Home Station", (val) => setState(() => _homeLocation = val));
                  } else {
                    _endController.text = _homeLocation!; 
                  }
                },
                onLongPress: () => _showSetLocationDialog("Change Home", (val) => setState(() => _homeLocation = val)),
              ),
              _buildQuickAction(
                icon: Icons.work, 
                label: _workLocation ?? "Set Work", 
                isSet: _workLocation != null, 
                onTap: () {
                  if (_workLocation == null) {
                    _showSetLocationDialog("Set Work Station", (val) => setState(() => _workLocation = val));
                  } else {
                    _endController.text = _workLocation!;
                  }
                },
                onLongPress: () => _showSetLocationDialog("Change Work", (val) => setState(() => _workLocation = val)),
              ),
              _buildQuickAction(
                icon: Icons.bookmark, 
                label: "Saved", 
                isSet: false, // The saved button just acts like a normal menu
                onTap: _openSavedLocationsSheet,
                onLongPress: _openSavedLocationsSheet,
              ),
            ],
          ),
          const SizedBox(height: 25),

          const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          if (_recentSearches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No recent searches. Try finding a route!", style: TextStyle(color: Colors.grey)),
            ),
          ..._recentSearches.map((route) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF6DA4C2)),
              title: Text("${route['start']} → ${route['end']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                _startController.text = route['start']!;
                _endController.text = route['end']!;
                _performSearch(route['start']!, route['end']!);
              },
            ),
          )),
        ],
      ),
    );
  }

  // THE FIX: Upgraded the quick action builder to include the Edit Badge and text limits
  Widget _buildQuickAction({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap, 
    required VoidCallback onLongPress,
    required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // You can still long-press it if you want!
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Icon(icon, color: const Color(0xFF6DA4C2), size: 30),
              ),
              if (isSet)
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: onLongPress, // Tapping the badge triggers the "change" dialog!
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 80, // Caps the width so long station names don't break the layout
            child: Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
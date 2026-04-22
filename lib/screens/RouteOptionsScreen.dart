import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'MapScreen.dart';

class RouteOptionsScreen extends StatefulWidget {
  final String start;
  final String end;
  
  const RouteOptionsScreen({super.key, required this.start, required this.end});

  @override
  State<RouteOptionsScreen> createState() => _RouteOptionsScreenState();
}

class _RouteOptionsScreenState extends State<RouteOptionsScreen> {
  Future<Map<String, dynamic>> _fetchOptions() async {
    final startEncoded = Uri.encodeComponent(widget.start.trim());
    final endEncoded = Uri.encodeComponent(widget.end.trim());
    
    // Remember to use 10.0.2.2 for Android Emulator connecting to localhost
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/route?start=$startEncoded&end=$endEncoded'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Route Options", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${widget.start} → ${widget.end}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchOptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6DA4C2)));
          } else if (snapshot.hasError || snapshot.data!['success'] == false) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Error: Could not calculate route. Check your internet connection or station spelling.", style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ));
          }

          final data = snapshot.data!;
          final List options = data['options'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text("Available Metro Routes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              // THE FIX: Dynamically generate cards based on the length of the list!
              ...options.asMap().entries.map((entry) {
                int index = entry.key;
                var option = entry.value;
                
                // Alternate colors for UI flair if we ever add more options later
                Color cardColor = index == 0 ? const Color(0xFF6DA4C2) : const Color(0xFFD4A373);
                
                return _buildRouteCard(
                  context: context,
                  data: data,
                  title: option['type'] ?? 'Metro Route',
                  subtitle: option['desc'] ?? '',
                  color: cardColor,
                  icon: Icons.directions_subway,
                  duration: "${option['time']} min",
                  traffic: option['traffic'] ?? 'Low',
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteCard({required BuildContext context, required Map<String, dynamic> data, required String title, required String subtitle, required Color color, required IconData icon, required String duration, required String traffic}) {
    Color trafficColor = Colors.green;
    if (traffic == "Medium") trafficColor = Colors.orange;
    if (traffic == "Heavy") trafficColor = Colors.red;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(pathData: data))),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 30),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(Icons.access_time, "Duration", duration, Colors.black),
                  _buildStat(Icons.group, "Crowds", traffic, trafficColor), // Changed from 'Traffic' to 'Crowds' for Metro!
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String val, Color valueColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor)),
      ],
    );
  }
}
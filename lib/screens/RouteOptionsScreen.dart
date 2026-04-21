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
    
    // Fetching the real route from your Python backend!
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data!['success'] == false) {
            return Center(child: Text("Error: Could not find route. Ensure stations are spelled correctly.", style: TextStyle(color: Colors.red)));
          }

          final data = snapshot.data!;
          final List options = data['options'];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text("Choose Your Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              // We pass the full data package to the MapScreen when a card is tapped
              _buildRouteCard(
                context: context,
                data: data,
                title: "Fastest Route",
                subtitle: "Optimized by ACO Algorithm",
                color: const Color(0xFF6DA4C2),
                icon: Icons.flash_on,
                duration: "${options[0]['time']} min",
                traffic: "Low", // Simulated API congestion
              ),
              _buildRouteCard(
                context: context,
                data: data,
                title: "Alternative Route",
                subtitle: "Standard algorithm",
                color: const Color(0xFFD4A373),
                icon: Icons.alt_route,
                duration: "${options[1]['time']} min",
                traffic: "Medium",
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteCard({required BuildContext context, required Map<String, dynamic> data, required String title, required String subtitle, required Color color, required IconData icon, required String duration, required String traffic}) {
    return GestureDetector(
      // Navigating and passing the REAL points!
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
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Space evenly without cost
                children: [
                  _buildStat(Icons.access_time, "Duration", duration),
                  _buildStat(Icons.traffic, "Traffic", traffic),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String val) {
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
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
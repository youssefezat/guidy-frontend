import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'models.dart'; // Import the models we just made

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Fetches station names for autocomplete
  Future<List<String>> fetchStations() async {
    final response = await http.get(Uri.parse('$baseUrl/stations'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['stations']);
    }
    throw Exception('Failed to load stations');
  }

  // Fetches the calculated route options from your Python backend
  Future<Map<String, dynamic>> fetchRoute(String start, String end) async {
    final response = await http.get(
      Uri.parse('$baseUrl/route?start=${Uri.encodeComponent(start)}&end=${Uri.encodeComponent(end)}'),
    );
    return json.decode(response.body);
  }
}

class LocationService {
  // Handles all GPS permission logic
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }
}
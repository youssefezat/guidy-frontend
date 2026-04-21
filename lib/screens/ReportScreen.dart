import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedSeverity = "Medium";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Report an Issue", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Help improve the community", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What's the issue?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildIssueToggle(Icons.traffic, "Heavy Traffic", true),
                _buildIssueToggle(Icons.car_crash, "Accident", false),
                _buildIssueToggle(Icons.access_time, "Service Delay", false),
                _buildIssueToggle(Icons.groups, "Overcrowded", false),
                _buildIssueToggle(Icons.build, "Vehicle Breakdown", false),
                _buildIssueToggle(Icons.warning, "Other Issue", false),
              ],
            ),
            const SizedBox(height: 25),
            
            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter location or use current",
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),

            const Text("Severity Level", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              // FIXED: Changed from spaceEvenColored to spaceEvenly
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSeverityButton("Low", Colors.grey[200]!, Colors.black),
                _buildSeverityButton("Medium", const Color(0xFFD4A373), Colors.white),
                _buildSeverityButton("High", Colors.grey[200]!, Colors.black),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Description (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Provide additional details...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DA4C2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIssueToggle(IconData icon, String label, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildSeverityButton(String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () => setState(() => selectedSeverity = label),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
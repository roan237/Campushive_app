import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilterPanel extends StatefulWidget {
  final String selectedLocation;
  final String selectedCourse;
  final String selectedFees;
  final String selectedPlacement;
  final String selectedType;

  const FilterPanel({
    super.key,
    required this.selectedLocation,
    required this.selectedCourse,
    required this.selectedFees,
    required this.selectedPlacement,
    required this.selectedType,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // Controllers
  late TextEditingController locationC;
  late TextEditingController feesC;
  late TextEditingController placementC;

  // Variables for Dropdowns
  late String currentCourse;
  late String currentType;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with values passed from the main screen
    locationC = TextEditingController(text: widget.selectedLocation);
    feesC = TextEditingController(text: widget.selectedFees);
    placementC = TextEditingController(text: widget.selectedPlacement);
    currentCourse = widget.selectedCourse;
    currentType = widget.selectedType;
  }

  @override
  void dispose() {
    locationC.dispose();
    feesC.dispose();
    placementC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Smart Filters",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 25),

            // Location Field
            _filterField(controller: locationC, icon: Icons.location_on, label: "Location"),
            const SizedBox(height: 15),

            // Course Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("colleges").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                List<String> courses = [];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data["courses"] != null) {
                    for (var c in data["courses"]) {
                      String name = (c["Name"] ?? "").toString().toLowerCase();
                      if (name.isNotEmpty && !courses.contains(name)) courses.add(name);
                    }
                  }
                }

                return _dropdownContainer(
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: currentCourse.isEmpty ? null : currentCourse,
                    hint: const Text("Course"),
                    items: courses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setState(() => currentCourse = value ?? ""),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.school, color: Color(0xFF6A11CB)),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),
            _filterField(controller: feesC, icon: Icons.currency_rupee, label: "Maximum Fees"),
            const SizedBox(height: 15),
            _filterField(controller: placementC, icon: Icons.bar_chart, label: "Minimum Placement %"),
            const SizedBox(height: 15),

            // College Type Dropdown
            _dropdownContainer(
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: currentType.isEmpty ? null : currentType,
                hint: const Text("College Type"),
                items: const [
                  DropdownMenuItem(value: "government", child: Text("Government")),
                  DropdownMenuItem(value: "aided", child: Text("Aided")),
                  DropdownMenuItem(value: "private", child: Text("Private")),
                ],
                onChanged: (value) => setState(() => currentType = value ?? ""),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.account_balance, color: Color(0xFF6A11CB)),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  // SEND DATA BACK TO MAIN SCREEN
                  Navigator.pop(context, {
                    "location": locationC.text.trim().toLowerCase(),
                    "course": currentCourse,
                    "fees": feesC.text.trim(),
                    "placement": placementC.text.trim(),
                    "type": currentType,
                  });
                },
                child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 10),

            // Clear Button
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  "location": "",
                  "course": "",
                  "fees": "",
                  "placement": "",
                  "type": "",
                });
              },
              child: const Text("Clear Filters", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterField({required TextEditingController controller, required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
          hintText: label,
        ),
      ),
    );
  }

  Widget _dropdownContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: child,
    );
  }
}
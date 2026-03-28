import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareCollegesPage extends StatefulWidget {
  const CompareCollegesPage({super.key});

  @override
  State<CompareCollegesPage> createState() => _CompareCollegesPageState();
}

class _CompareCollegesPageState extends State<CompareCollegesPage> {
  String? collegeA, collegeB, collegeC, collegeD;
  String? courseA, courseB, courseC, courseD;

  bool showCollegeC = false;
  bool showCollegeD = false;
  bool showResult = false;

  // Key is now "CollegeName (CourseName)" to allow comparing same college multiple times
  Map<String, Map<String, dynamic>> comparisonData = {};

  int bestPlacement = 0;
  int bestRank = 999999;
  int bestAccreditation = 0;

  int accreditationScore(String value) {
    value = value.toLowerCase().trim();
    // Handles "Accredited", "Yes", or "NAAC A++" style strings
    return (value == "accredited" || value == "yes" || value.contains("naac")) ? 1 : 0;
  }

  Future<Map<String, dynamic>?> getCourseData(String college, String course) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("colleges")
        .where("name", isEqualTo: college)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final docData = snapshot.docs.first.data();

    // Top-level college data
    int placement = int.tryParse(docData["Placement Ratio"].toString()) ?? 0;
    List courses = docData["courses"] ?? [];

    // Specific course data inside the list
    for (var c in courses) {
      if (c["Name"] == course) {
        return {
          "placementRatio": placement,
          "last rank": c["last rank"],
          "accreditation": c["accreditation"]
        };
      }
    }
    return null;
  }

  Future<void> calculateWinner() async {
    comparisonData.clear();
    bestPlacement = 0;
    bestRank = 999999;
    bestAccreditation = 0;

    List<Map<String, String?>> selections = [
      {"college": collegeA, "course": courseA},
      {"college": collegeB, "course": courseB},
      {"college": collegeC, "course": courseC},
      {"college": collegeD, "course": courseD},
    ];

    selections.removeWhere((e) => e["college"] == null || e["course"] == null);

    for (var s in selections) {
      final data = await getCourseData(s["college"]!, s["course"]!);

      if (data != null) {
        int placement = int.tryParse(data["placementRatio"].toString()) ?? 0;
        int rank = int.tryParse(data["last rank"].toString()) ?? 999999;
        int acc = accreditationScore(data["accreditation"].toString());

        // Create a unique key so we can compare same college with different courses
        String uniqueKey = "${s["college"]} (${s["course"]})";

        comparisonData[uniqueKey] = {
          "collegeName": s["college"],
          "courseName": s["course"],
          "placement": placement,
          "rank": rank,
          "accreditation": acc
        };

        // Track bests for color highlighting
        if (placement > bestPlacement) bestPlacement = placement;
        if (rank < bestRank && rank != 0) bestRank = rank;
        if (acc > bestAccreditation) bestAccreditation = acc;
      }
    }

    setState(() {
      showResult = true;
    });
  }

  void showComparisonResult() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(Icons.compare_arrows, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      "Comparison Result",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
                    columns: [
                      const DataColumn(label: Text("Feature", style: TextStyle(fontWeight: FontWeight.bold))),
                      ...comparisonData.values.map((v) => DataColumn(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(v["collegeName"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(v["courseName"], style: const TextStyle(fontSize: 9, color: Colors.black54)),
                          ],
                        ),
                      ))
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text("Placement")),
                        ...comparisonData.values.map((v) => DataCell(Text("${v["placement"]}%",
                            style: TextStyle(
                                color: v["placement"] == bestPlacement ? Colors.green : Colors.red,
                                fontWeight: v["placement"] == bestPlacement ? FontWeight.bold : FontWeight.normal)))).toList(),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text("Last Rank")),
                        ...comparisonData.values.map((v) => DataCell(Text("${v["rank"]}",
                            style: TextStyle(
                                color: v["rank"] == bestRank ? Colors.green : Colors.red,
                                fontWeight: v["rank"] == bestRank ? FontWeight.bold : FontWeight.normal)))).toList(),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text("Accredited")),
                        ...comparisonData.values.map((v) => DataCell(Text(v["accreditation"] == 1 ? "Yes" : "No",
                            style: TextStyle(
                                color: v["accreditation"] == bestAccreditation ? Colors.green : Colors.red,
                                fontWeight: v["accreditation"] == bestAccreditation ? FontWeight.bold : FontWeight.normal)))).toList(),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text("Compare Colleges", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildCollegeSection("Selection 1", collegeA, courseA,
                    (v) => setState(() { collegeA = v; courseA = null; }),
                    (v) => setState(() { courseA = v; })),

            buildCollegeSection("Selection 2", collegeB, courseB,
                    (v) => setState(() { collegeB = v; courseB = null; }),
                    (v) => setState(() { courseB = v; })),

            if (showCollegeC)
              buildCollegeSection("Selection 3", collegeC, courseC,
                      (v) => setState(() { collegeC = v; courseC = null; }),
                      (v) => setState(() { courseC = v; }),
                  removable: true, onRemove: () => setState(() { showCollegeC = false; collegeC = null; courseC = null; })),

            if (showCollegeD)
              buildCollegeSection("Selection 4", collegeD, courseD,
                      (v) => setState(() { collegeD = v; courseD = null; }),
                      (v) => setState(() { courseD = v; }),
                  removable: true, onRemove: () => setState(() { showCollegeD = false; collegeD = null; courseD = null; })),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                if (!showCollegeC) setState(() => showCollegeC = true);
                else if (!showCollegeD) setState(() => showCollegeD = true);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Another Comparison"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A11CB),
                side: const BorderSide(color: Color(0xFF6A11CB)),
                shape: StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: StadiumBorder(),
                ),
                onPressed: () async {
                  if (collegeA == null || collegeB == null || courseA == null || courseB == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least 2 complete options")));
                    return;
                  }
                  await calculateWinner();
                  showComparisonResult();
                },
                child: const Text("Compare Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCollegeSection(String title, String? college, String? course, Function(String?) onCollege, Function(String?) onCourse, {bool removable = false, VoidCallback? onRemove}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (removable) IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: onRemove)
          ]),
          const SizedBox(height: 12),
          buildCollegeCard(title, college, onCollege),
          const SizedBox(height: 12),
          buildCourseSelector(college, course, onCourse),
        ],
      ),
    );
  }

  Widget buildCollegeCard(String title, String? selectedValue, Function(String?) onChanged) {
    return InkWell(
      onTap: () async {
        final selected = await showSearch<String>(context: context, delegate: CollegeSearchDelegate());
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(color: const Color(0xFFF4F4FA), borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Text(selectedValue ?? "Search College", style: TextStyle(color: selectedValue == null ? Colors.black: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget buildCourseSelector(String? college, String? selectedCourse, Function(String?) onChanged) {
    if (college == null) return const Text("Please select a college first", style: TextStyle(fontSize: 12, color: Colors.black));
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection("colleges").where("name", isEqualTo: college).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("No college found");
        final data = docs.first.data() as Map<String, dynamic>;
        List courses = data["courses"] ?? [];
        return DropdownButtonFormField<String>(
          value: selectedCourse,
          hint: const Text("Select Department/Course"),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            filled: true,
            fillColor: const Color(0xFFF4F4FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
          items: courses.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c["Name"], child: Text(c["Name"]))).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class CollegeSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ""));

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("colleges").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!.docs.where((doc) => doc["name"].toString().toLowerCase().contains(query.toLowerCase())).toList();
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final name = results[index]["name"];
            return ListTile(title: Text(name), onTap: () => close(context, name));
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
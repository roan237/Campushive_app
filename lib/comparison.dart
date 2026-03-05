import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareCollegesPage extends StatefulWidget {
  const CompareCollegesPage({super.key});

  @override
  State<CompareCollegesPage> createState() => _CompareCollegesPageState();
}

class _CompareCollegesPageState extends State<CompareCollegesPage> {
  String? collegeA;
  String? collegeB;
  String? collegeC;
  String? collegeD;

  bool showCollegeC = false;
  bool showCollegeD = false;
  bool showResult = false;

  List<String> selectedForComparison = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Compare Colleges",
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildCollegeCard(
              title: "College A",
              icon: Icons.school,
              selectedValue: collegeA,
              onChanged: (val) {
                setState(() {
                  collegeA = val;
                  showResult = false;
                });
              },
            ),

            const SizedBox(height: 18),

            buildCollegeCard(
              title: "College B",
              icon: Icons.apartment,
              selectedValue: collegeB,
              onChanged: (val) {
                setState(() {
                  collegeB = val;
                  showResult = false;
                });
              },
            ),

            const SizedBox(height: 18),

            if (showCollegeC)
              Column(
                children: [
                  buildCollegeCard(
                    title: "College C",
                    icon: Icons.account_balance,
                    selectedValue: collegeC,
                    removable: true,
                    onRemove: () {
                      setState(() {
                        showCollegeC = false;
                        showCollegeD = false;
                        collegeC = null;
                        collegeD = null;
                        showResult = false;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        collegeC = val;
                        showResult = false;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),

            if (showCollegeD)
              Column(
                children: [
                  buildCollegeCard(
                    title: "College D",
                    icon: Icons.location_city,
                    selectedValue: collegeD,
                    removable: true,
                    onRemove: () {
                      setState(() {
                        showCollegeD = false;
                        collegeD = null;
                        showResult = false;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        collegeD = val;
                        showResult = false;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (!showCollegeC) {
                        setState(() {
                          showCollegeC = true;
                        });
                      } else if (!showCollegeD) {
                        setState(() {
                          showCollegeD = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Another College"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (collegeA == null || collegeB == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select College A and College B!"),
                      ),
                    );
                    return;
                  }

                  final selected = <String?>[
                    collegeA,
                    collegeB,
                    if (showCollegeC) collegeC,
                    if (showCollegeD) collegeD,
                  ].where((e) => e != null).cast<String>().toList();

                  if (selected.toSet().length != selected.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select different colleges."),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    selectedForComparison = selected;
                    showResult = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Compare Now",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (showResult)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedForComparison
                    .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    "🏫 $c",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildCollegeCard({
    required String title,
    required IconData icon,
    required String? selectedValue,
    required Function(String?) onChanged,
    bool removable = false,
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6A11CB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Select $title",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (removable)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (context) {
                  TextEditingController searchController =
                  TextEditingController();

                  List<String> results = [];

                  return StatefulBuilder(
                    builder: (context, setStateDialog) {

                      Future<void> searchCollege(String query) async {

                        if (query.isEmpty) {
                          setStateDialog(() {
                            results = [];
                          });
                          return;
                        }

                        final snapshot = await FirebaseFirestore.instance
                            .collection("colleges")
                            .get();

                        List<String> temp = snapshot.docs
                            .map((doc) => doc["name"].toString())
                            .where((name) => name
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();

                        setStateDialog(() {
                          results = temp;
                        });
                      }

                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text("Search College"),
                        content: SizedBox(
                          height: 350,
                          child: Column(
                            children: [

                              TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  searchCollege(value);
                                },
                                decoration: const InputDecoration(
                                  hintText: "Search college...",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Expanded(
                                child: ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(results[index]),
                                      onTap: () {
                                        Navigator.pop(
                                            context, results[index]);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (selected != null) {
                onChanged(selected);
              }
            },

            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedValue ?? "Search college",
                    style: TextStyle(
                      color: selectedValue == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  const Icon(Icons.search),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
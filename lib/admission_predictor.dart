import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdmissionPredictorPage extends StatefulWidget {
  const AdmissionPredictorPage({super.key});

  @override
  State<AdmissionPredictorPage> createState() => _AdmissionPredictorPageState();
}

class _AdmissionPredictorPageState extends State<AdmissionPredictorPage> {

  final TextEditingController rankController = TextEditingController();

  String? selectedCollegeId;
  String? selectedCourse;
  int? lastRank;
  double? chance;

  // ---------------- CHANCE CALCULATION ----------------

  double calculateChance(int userRank, int lastRank) {

    double ratio = lastRank / userRank;

    double chance = ratio * 70;

    if (chance > 95) chance = 95;
    if (chance < 5) chance = 5;

    return chance;
  }

  // ---------------- CHANCE COLOR ----------------

  Color chanceColor(double value) {
    if (value >= 75) return Colors.green;
    if (value >= 50) return Colors.orange;
    return Colors.red;
  }

  // ---------------- CHANCE LABEL ----------------

  String chanceLabel(double value) {
    if (value >= 75) return "High Chance";
    if (value >= 50) return "Moderate Chance";
    return "Low Chance";
  }

  // ---------------- PREDICT FUNCTION ----------------

  void predictChance() {

    if(rankController.text.isEmpty || lastRank == null){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter rank and select college & course"),
        ),
      );

      return;
    }

    int userRank = int.parse(rankController.text);

    double result = calculateChance(userRank, lastRank!);

    setState(() {
      chance = result;
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF3F0F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Admission Predictor",
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            // ---------------- RANK INPUT ----------------

            TextField(
              controller: rankController,
              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                hintText: "Enter KEAM Rank",
                prefixIcon: const Icon(Icons.numbers),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height:20),

            // ---------------- COLLEGE DROPDOWN ----------------

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("colleges")
                  .snapshots(),

              builder: (context, snapshot) {

                if(!snapshot.hasData){
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField(
                      isExpanded: true,
                  value: selectedCollegeId,

                  hint: const Text("Select College"),

                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  items: docs.map((doc){

                    final data = doc.data() as Map<String,dynamic>;

                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        data["name"],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );

                  }).toList(),

                  onChanged: (value){

                    setState(() {

                      selectedCollegeId = value as String?;
                      selectedCourse = null;
                      lastRank = null;

                    });
                  },),
                );
              },
            ),

            const SizedBox(height:20),

            // ---------------- COURSE DROPDOWN ----------------

            if(selectedCollegeId != null)

              StreamBuilder<DocumentSnapshot>(

                stream: FirebaseFirestore.instance
                    .collection("colleges")
                    .doc(selectedCollegeId)
                    .snapshots(),

                builder: (context, snapshot){

                  if(!snapshot.hasData){
                    return const SizedBox();
                  }

                  final data =
                  snapshot.data!.data() as Map<String,dynamic>;

                  List courses = data["courses"] ?? [];

                  return DropdownButtonFormField(

                    value: selectedCourse,

                    hint: const Text("Select Course"),

                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    items: courses.map((c){

                      return DropdownMenuItem(

                        value: c["Name"],

                        child: Text(c["Name"]),

                        onTap: (){
                          lastRank = c["last rank"];
                        },
                      );

                    }).toList(),

                    onChanged: (value){

                      setState(() {
                        selectedCourse = value as String?;
                      });
                    },
                  );
                },
              ),

            const SizedBox(height:30),

            // ---------------- PREDICT BUTTON ----------------

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  padding: const EdgeInsets.symmetric(vertical:16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                onPressed: predictChance,

                child: const Text(
                  "Predict Admission Chance",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height:30),

            // ---------------- RESULT CARD ----------------

            if(chance != null)

              Container(

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8)
                  ],
                ),

                child: Column(

                  children: [

                    const Text(
                      "Admission Chance",
                      style: TextStyle(
                        fontSize:18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height:10),

                    Text(
                      "${chance!.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize:42,
                        fontWeight: FontWeight.bold,
                        color: chanceColor(chance!),
                      ),
                    ),

                    const SizedBox(height:8),

                    Text(
                      chanceLabel(chance!),
                      style: TextStyle(
                        fontSize:16,
                        fontWeight: FontWeight.bold,
                        color: chanceColor(chance!),
                      ),
                    ),

                    const SizedBox(height:20),

                    LinearProgressIndicator(
                      value: chance! / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      color: chanceColor(chance!),
                    ),

                    const SizedBox(height:20),

                    const Text(
                      "Prediction based on previous KEAM last rank data. "
                          "Actual allotment may vary depending on counselling rounds.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:12,
                        color: Colors.grey,
                      ),
                    )

                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }
}
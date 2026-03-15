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

  String? courseA;
  String? courseB;
  String? courseC;
  String? courseD;

  bool showCollegeC = false;
  bool showCollegeD = false;

  bool showResult = false;

  Map<String, Map<String, dynamic>> comparisonData = {};

  int bestPlacement = 0;
  int bestRank = 999999;
  int bestAccreditation = 0;
  int accreditationScore(String value){
    value = value.toLowerCase().trim();

    if(value == "accredited") {
      return 1;
    } else {
      return 0;
    }
  }

  Future<Map<String,dynamic>?> getCourseData(String college,String course) async {

    final snapshot = await FirebaseFirestore.instance
        .collection("colleges")
        .where("name", isEqualTo: college)
        .get();

    if(snapshot.docs.isEmpty) return null;

    final docData = snapshot.docs.first.data();

    int placement =
        int.tryParse(docData["Placement Ratio"].toString()) ?? 0;

    List courses = docData["courses"] ?? [];

    for(var c in courses){

      if(c["Name"] == course){

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

    List<Map<String,String?>> selections = [
      {"college":collegeA,"course":courseA},
      {"college":collegeB,"course":courseB},
      {"college":collegeC,"course":courseC},
      {"college":collegeD,"course":courseD},
    ];

    selections.removeWhere((e)=>e["college"]==null || e["course"]==null);

    for(var s in selections){

      final data = await getCourseData(s["college"]!,s["course"]!);

      if(data!=null){

        int placement =
            int.tryParse(data["placementRatio"].toString()) ?? 0;

        int rank =
            int.tryParse(data["last rank"].toString()) ?? 999999;

        int acc =
        accreditationScore(data["accreditation"]);

        comparisonData[s["college"]!] = {
          "course": s["course"],
          "placement": placement,
          "rank": rank,
          "accreditation": acc
        };

        if(placement > bestPlacement) bestPlacement = placement;
        if(rank < bestRank) bestRank = rank;
        if(acc > bestAccreditation) bestAccreditation = acc;

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

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),

          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// HEADER
                Row(
                  children: const [

                    Icon(
                      Icons.compare_arrows,
                      color: Colors.deepPurple,
                    ),

                    SizedBox(width: 8),

                    Text(
                      "Comparison Result",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 20),

                /// TABLE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: DataTable(

                    columnSpacing: 25,

                    headingRowColor: MaterialStateProperty.all(
                        Colors.deepPurple.shade50),

                    columns: [

                      const DataColumn(
                        label: Text(
                          "Feature",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      ...comparisonData.keys.map(
                            (college) => DataColumn(
                          label: Text(
                            college,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )

                    ],

                    rows: [

                      /// Placement Row
                      DataRow(
                        cells: [
                          const DataCell(Row(
                            children: [
                              Icon(Icons.work, size: 18),
                              SizedBox(width: 5),
                              Text("Placement"),
                            ],
                          )),

                          ...comparisonData.entries.map((e){

                            int placement = e.value["placement"];

                            return DataCell(
                              Text(
                                "$placement%",
                                style: TextStyle(
                                  color: placement == bestPlacement
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                          }).toList(),

                        ],
                      ),

                      /// Rank Row
                      DataRow(
                        cells: [
                          const DataCell(Row(
                            children: [
                              Icon(Icons.leaderboard, size: 18),
                              SizedBox(width: 5),
                              Text("Last Rank"),
                            ],
                          )),

                          ...comparisonData.entries.map((e){

                            int rank = e.value["rank"];

                            return DataCell(
                              Text(
                                "$rank",
                                style: TextStyle(
                                  color: rank == bestRank
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                          }).toList(),

                        ],
                      ),

                      /// Accreditation Row
                      DataRow(
                        cells: [
                          const DataCell(Row(
                            children: [
                              Icon(Icons.verified, size: 18),
                              SizedBox(width: 5),
                              Text("Accredited"),
                            ],
                          )),

                          ...comparisonData.entries.map((e){

                            int acc = e.value["accreditation"];

                            return DataCell(
                              Text(
                                acc == 1 ? "Yes" : "No",
                                style: TextStyle(
                                  color: acc == bestAccreditation
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                          }).toList(),

                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// CLOSE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.white),
                    ),

                  ),
                )

              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildCourseSelector(String? college,String? selectedCourse,Function(String?) onChanged){

    if(college == null){
    return const Text("Select college first");
    }

    return FutureBuilder(

    future:FirebaseFirestore.instance
        .collection("colleges")
        .where("name", isEqualTo: college)
        .get(),

    builder: (context,snapshot){

    if(!snapshot.hasData){
    return const CircularProgressIndicator();
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
      return const Text("No courses found");
    }

    final data = docs.first.data() as Map<String, dynamic>;
    List courses = data["courses"] ?? [];

    return DropdownButtonFormField<String>(

    value: selectedCourse,
    hint: const Text("Select Course"),

    items: courses.map<DropdownMenuItem<String>>((course){

    return DropdownMenuItem(
    value: course["Name"],
    child: Text(course["Name"]),
    );

    }).toList(),

    onChanged: onChanged,

    );

    },

    );


  }

  Widget buildCollegeSection(
      String title,
      String? college,
      String? course,
      Function(String?) onCollege,
      Function(String?) onCourse,
      {bool removable=false,
        VoidCallback? onRemove}){


    return Container(

    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom:20),

    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(.05),
    blurRadius: 10,
    )
    ],
    ),

    child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

    Row(

    children: [

    Expanded(
    child: Text(
    title,
    style: const TextStyle(
    fontSize:16,
    fontWeight: FontWeight.bold),
    ),
    ),

    if(removable)
    IconButton(
    icon: const Icon(Icons.close),
    onPressed: onRemove,
    )

    ],

    ),

    const SizedBox(height:10),

    buildCollegeCard(title,college,onCollege),

    const SizedBox(height:10),

    buildCourseSelector(college,course,onCourse),

    ],

    ),

    );


  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(

    backgroundColor: const Color(0xFFF7F7FB),

    appBar: AppBar(
    title: const Text("Compare Colleges"),
    centerTitle: true,
    ),

    body: SingleChildScrollView(

    padding: const EdgeInsets.all(20),

    child: Column(

    children: [

    buildCollegeSection(
    "College A",
    collegeA,
    courseA,
    (v){setState((){collegeA=v;courseA=null;showResult=false;});},
    (v){setState((){courseA=v;showResult=false;});}
    ),

    buildCollegeSection(
    "College B",
    collegeB,
    courseB,
    (v){setState((){collegeB=v;courseB=null;showResult=false;});},
    (v){setState((){courseB=v;showResult=false;});}
    ),

    if(showCollegeC)
    buildCollegeSection(
    "College C",
    collegeC,
    courseC,
    (v){setState((){collegeC=v;courseC=null;showResult=false;});},
    (v){setState((){courseC=v;showResult=false;});},
    removable:true,
    onRemove:(){
    setState(() {
    showCollegeC=false;
    collegeC=null;
    courseC=null;
    });
    }
    ),

    if(showCollegeD)
    buildCollegeSection(
    "College D",
    collegeD,
    courseD,
    (v){setState((){collegeD=v;courseD=null;showResult=false;});},
    (v){setState((){courseD=v;showResult=false;});},
    removable:true,
    onRemove:(){
    setState(() {
    showCollegeD=false;
    collegeD=null;
    courseD=null;
    });
    }
    ),

    const SizedBox(height:10),

      const SizedBox(height: 10),

      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF6A11CB),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF6A11CB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
        ),

        icon: const Icon(Icons.add, color: Colors.white),

        label: const Text(
          "Add Another College",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        onPressed: () {
          if (!showCollegeC) {
            setState(() => showCollegeC = true);
          } else if (!showCollegeD) {
            setState(() => showCollegeD = true);
          }
        },
      ),

    const SizedBox(height:25),

    SizedBox(

    width: double.infinity,
    height: 55,

    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),

      onPressed: () async {

        if (collegeA == null || collegeB == null ||
            courseA == null || courseB == null) {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Select at least 2 colleges and courses"),
            ),
          );

          return;
        }

        await calculateWinner();
        showComparisonResult();
      },

      child: const Text(
        "Compare Now",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    )
    ),

    const SizedBox(height:30),


    ],

    ),

    ),

    );


  }

  Widget buildCollegeCard(String title,String? selectedValue,Function(String?) onChanged){


    return TextField(

    readOnly: true,

    decoration: InputDecoration(
    hintText: selectedValue ?? "Search $title",
    prefixIcon: const Icon(Icons.search),
    filled: true,
    fillColor: const Color(0xFFF4F4FA),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide.none,
    ),
    ),

    onTap: () async {

    final selected = await showSearch<String>(
    context: context,
    delegate: CollegeSearchDelegate(),
    );

    if(selected!=null){
    onChanged(selected);
    }

    },

    );


  }

}

class CollegeSearchDelegate extends SearchDelegate<String>{

  @override
  List<Widget>? buildActions(BuildContext context){
    return [IconButton(icon: const Icon(Icons.clear),onPressed: ()=>query="")];
  }

  @override
  Widget? buildLeading(BuildContext context){
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: ()=>close(context,""),
    );
  }

  @override
  Widget buildResults(BuildContext context){


    return StreamBuilder(

    stream: FirebaseFirestore.instance
        .collection("colleges")
        .snapshots(),

    builder: (context,snapshot){

    if(!snapshot.hasData){
    return const Center(child: CircularProgressIndicator());
    }

    final results = snapshot.data!.docs.where((doc){

      final name = doc["name"].toString().toLowerCase();
    return name.contains(query.toLowerCase());

    }).toList();

    return ListView.builder(

    itemCount: results.length,

    itemBuilder: (context,index){

      final name = results[index]["name"];

    return ListTile(
    title: Text(name),
    onTap: ()=>close(context,name),
    );

    },

    );

    },

    );


  }

  @override
  Widget buildSuggestions(BuildContext context){
    return buildResults(context);
  }

}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'comparison.dart';
import 'myprofile.dart';
import 'admission_predictor.dart';
import 'college_details.dart';
import 'explore_colleges.dart';
import 'signup.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // MOVE THESE LINES INSIDE MAIN
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Pass the value to your App
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; // Add this line

  // Add "required this.isLoggedIn" to the constructor
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const HomePage() : const SplashScreen(),
    );
  }
}
// ---------------- SPLASH SCREEN ----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 0;
  double scale = 0.6;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        opacity = 1;
        scale = 1;
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B1D6D),
      body: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(seconds: 2),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(seconds: 2),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.hive, size: 120, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  "CAMPUSHIVE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- ONBOARDING ----------------
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 27),
          child: Column(
            // Use spaceBetween so the Icon/Text group stays apart from the Button
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // 1. NESTED COLUMN: This groups the Icon and Text together
              Column(
                children: [
                  const SizedBox(height: 80), // Pushes the whole group down from the top
                  const Icon(
                    Icons.school,
                    size: 140,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20), // Controlled space between Icon and Welcome
                  const Text(
                    "Welcome to\nCampus Hive",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Explore KTU Colleges\nand courses",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // 2. THE BUTTON: Stays at the bottom
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B1D6D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- FIRESTORE SERVICE ----------------
class FirestoreAuthService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> emailExists(String email) async {
    final result = await _db
        .collection("users")
        .where("email", isEqualTo: email.trim().toLowerCase())
        .get();

    return result.docs.isNotEmpty;
  }

  static Future<String?> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      bool exists = await emailExists(email);
      if (exists) return "Email already exists";

      await _db.collection("users").add({
        "name": name.trim(),
        "email": email.trim().toLowerCase(),
        "password": password.trim(), // ⚠️ for learning only
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return "Signup failed: $e";
    }
  }

  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    final result = await _db
        .collection("users")
        .where("email", isEqualTo: email.trim().toLowerCase())
        .where("password", isEqualTo: password.trim())
        .get();

    return result.docs.isNotEmpty;
  }
}

// ---------------- SIGN UP ----------------


// ---------------- LOGIN ----------------


// ---------------- HOME PAGE ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final TextEditingController searchC = TextEditingController();
  String searchText = "";
  String selectedLocation = "";
  String selectedCourse = "";
  String selectedFees = "";
  String selectedPlacement = "";
  String selectedAccreditation = "";
  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THIS WRAPS YOUR ENTIRE PAGE TO CAPTURE THE BACK BUTTON
    return PopScope(
      canPop: false, // Prevents automatic back navigation to Login
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show the Exit Confirmation Dialog
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white, // Standard white background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded corners
            ),
            title: Row(
              children: const [
                Icon(Icons.hive, color: Colors.deepPurple, size: 28), // Hive Icon
                SizedBox(width: 12),
                Text(
                  'Exit Campus Hive?',
                  style: TextStyle(
                    color: Color(0xFF2D2D2D), // Dark grey text
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.4, // Line height for readability
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey, // Subtle color for 'No'
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Purple 'Yes' button
                  foregroundColor: Colors.white, // White text
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Pill-shaped button
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes, Exit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.only(right: 20, bottom: 20), // Button spacing
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F0F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: const [
              Icon(Icons.hive, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                "CAMPUS HIVE",
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ---------------- BODY (FIRESTORE LIST) ----------------
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: searchC,
              onChanged: (val) {
                setState(() {
                  searchText = val.trim().toLowerCase();
                });
              },
              onSubmitted: (value) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExploreCollegesPage(
                      search: value.trim().toLowerCase(),
                    ),
                  ),
                );
              },
              decoration: InputDecoration(
                hintText: "Search colleges...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Align(
                alignment: Alignment.centerRight,
                child:ElevatedButton.icon(
                  onPressed: _openFilterPanel,
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  label: const Text(
                    "Filters",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB), // your purple
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

// 🔥 TRENDING COLLEGES
            const Text(
              "🔥 Trending Colleges",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 190,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("colleges")
                    .where("trending", isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: docs.map((doc) {

                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 14),
                        child: _collegeCardFromFirestore(
                          docId: doc.id,
                          name: data["name"] ?? "",
                          imageUrl: data["imageUrl"] ?? "",
                          location: data["location"] ?? "",
                        ),
                      );

                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

// ⭐ TOP RANKED COLLEGES
            const Text(
              "⭐ Top Ranked Colleges",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 190,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("colleges")
                    .orderBy("ranking")
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: docs.map((doc) {

                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 14),
                        child: _collegeCardFromFirestore(
                          docId: doc.id,
                          name: data["name"] ?? "",
                          imageUrl: data["imageUrl"] ?? "",
                          location: data["location"] ?? "",
                        ),
                      );

                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

// 💼 BEST PLACEMENT COLLEGES
            const Text(
              "💼 Best Placement Colleges",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 190,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("colleges")
                    .orderBy("Placement Ratio", descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: docs.map((doc) {

                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 14),
                        child: _collegeCardFromFirestore(
                          docId: doc.id,
                          name: data["name"] ?? "",
                          imageUrl: data["imageUrl"] ?? "",
                          location: data["location"] ?? "",
                        ),
                      );

                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

// 🎓 EXPLORE COLLEGES


            const SizedBox(height: 15),

// Firestore colleges list
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExploreCollegesPage(),
                    ),
                  );
                },
                child: const Text(
                  "Explore More Colleges",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        // ---------------- BOTTOM NAV ----------------
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,

          // ADD THESE TWO LINES
          type: BottomNavigationBarType.fixed, // Stops icons from shifting/hiding labels
          showUnselectedLabels: true,          // Makes labels visible for all items

          onTap: (i) {
            setState(() => index = i);

            if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompareCollegesPage()),
              );
            } else if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdmissionPredictorPage(),
                ),
              );
            } else if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyProfilePage()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.compare), label: "Compare"),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Predictor"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "My Profile"),
          ],
        ),),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _chip(String text) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$text clicked")),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.deepPurple),
        ),
      ),
    );
  }
  void _openFilterPanel() {
    TextEditingController locationC =
    TextEditingController(text: selectedLocation);

    TextEditingController courseC =
    TextEditingController(text: selectedCourse);

    TextEditingController feesC =
    TextEditingController(text: selectedFees);

    TextEditingController placementC =
    TextEditingController(text: selectedPlacement);

    TextEditingController accC =
    TextEditingController(text: selectedAccreditation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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

                _filterField(
                  controller: locationC,
                  icon: Icons.location_on,
                  label: "Location",
                ),

                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection("colleges").snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    List<String> courses = [];

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      if (data["courses"] != null) {
                        for (var c in data["courses"]) {
                          String name = (c["Name"] ?? "").toString().toLowerCase();
                          if (name.isNotEmpty && !courses.contains(name)) {
                            courses.add(name);
                          }
                        }
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedCourse.isEmpty ? null : selectedCourse,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A11CB).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, color: Color(0xFF6A11CB)),
                          ),
                          hintText: "Course",
                        ),
                        items: courses.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value ?? "";
                          });
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                _filterField(
                  controller: feesC,
                  icon: Icons.currency_rupee,
                  label: "Maximum Fees",
                ),

                const SizedBox(height: 15),

                _filterField(
                  controller: placementC,
                  icon: Icons.bar_chart,
                  label: "Minimum Placement %",
                ),

                const SizedBox(height: 15),

                const SizedBox(height: 15),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedAccreditation.isEmpty ? null : selectedAccreditation,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFF6A11CB)),
                      ),
                      hintText: "Accreditation",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "accredited",
                        child: Text("Accredited"),
                      ),
                      DropdownMenuItem(
                        value: "not accredited",
                        child: Text("Not Accredited"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedAccreditation = value ?? "";
                      });
                    },
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {

                      setState(() {
                        selectedLocation =
                            locationC.text.trim().toLowerCase();



                        selectedFees =
                            feesC.text.trim();

                        selectedPlacement =
                            placementC.text.trim();

                        selectedAccreditation =
                            accC.text.trim().toLowerCase();
                      });

                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExploreCollegesPage(
                            location: selectedLocation,
                            course: selectedCourse,
                            maxFees: int.tryParse(selectedFees),
                            minPlacement: int.tryParse(selectedPlacement),
                            accreditation: selectedAccreditation,
                          ),
                        ),
                      );

                    },
                    child: const Text(
                      "Apply Filters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {

                    setState(() {
                      selectedLocation = "";
                      selectedCourse = "";
                      selectedFees = "";
                      selectedPlacement = "";
                      selectedAccreditation = "";
                    });

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Clear Filters",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },


    );
  }

  Widget _filterField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A11CB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF6A11CB)),
          ),
          hintText: label,
        ),
      ),
    );
  }

  Widget _collegeCardFromFirestore({
    required String docId,
    required String name,
    required String imageUrl,
    required String location,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.toString().trim().isEmpty
                ? Container(
              width: 80,
              height: 80,
              color: Colors.deepPurple.shade100,
              child: const Icon(Icons.school,
                  size: 40, color: Colors.deepPurple),
            )
                : Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.deepPurple.shade100,
                  child: const Icon(Icons.school,
                      size: 40, color: Colors.deepPurple),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (location.toString().trim().isNotEmpty)
                  Text(
                    location,
                    style: const TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollegeDetailsPage(docId: docId),
                      ),
                    );
                  },
                  child: const Text("View details"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

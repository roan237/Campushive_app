import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'comparison.dart';
import 'myprofile.dart';
import 'admission_predictor.dart';
import 'college_details.dart';
import 'explore_colleges.dart';
import 'admission_predictor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// ---------------- APP ROOT ----------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
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
      backgroundColor: const Color(0xFFF3F0F7),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 15),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.school, size: 140, color: Colors.deepPurple),
              const Column(
                children: [
                  Text(
                    "Welcome to\nCampus Hive",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Explore KTU Colleges\nand courses",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B1D6D),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController confirmC = TextEditingController();

  bool loading = false;

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _signup() async {
    String name = nameC.text;
    String email = emailC.text;
    String pass = passC.text;
    String confirm = confirmC.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showMsg("Please fill all fields");
      return;
    }

    if (!email.contains("@")) {
      _showMsg("Enter a valid email");
      return;
    }

    if (pass.length < 6) {
      _showMsg("Password must be at least 6 characters");
      return;
    }

    if (pass != confirm) {
      _showMsg("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    String? error = await FirestoreAuthService.signupUser(
      name: name,
      email: email,
      password: pass,
    );

    setState(() => loading = false);

    if (error == null) {
      _showMsg("Signup successful ✅");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _showMsg(error);
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F7),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 15),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.hive, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 10),
                const Text("Create An Account"),
                const SizedBox(height: 24),
                TextField(
                  controller: nameC,
                  decoration: _input("Name", Icons.person),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailC,
                  decoration: _input("Email Address", Icons.email),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: _input("Password", Icons.lock),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmC,
                  obscureText: true,
                  decoration: _input("Confirm Password", Icons.lock_outline),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B1D6D),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 80,
                    ),
                  ),
                  onPressed: loading ? null : _signup,
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    "SIGN UP",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Have an account already? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- LOGIN ----------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  bool loading = false;

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _login() async {
    String email = emailC.text;
    String pass = passC.text;

    if (email.isEmpty || pass.isEmpty) {
      _showMsg("Please enter email and password");
      return;
    }

    setState(() => loading = true);

    bool ok = await FirestoreAuthService.loginUser(
      email: email,
      password: pass,
    );

    setState(() => loading = false);

    if (ok) {
      _showMsg("Login success ✅");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _showMsg("Invalid email or password ❌");
    }
  }

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F7),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 15),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.hive, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 10),
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text("Login to continue"),
                const SizedBox(height: 24),
                TextField(
                  controller: emailC,
                  decoration: _input("Email Address", Icons.email),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: _input("Password", Icons.lock),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?"),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B1D6D),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 80,
                    ),
                  ),
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    "LOG IN",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return Scaffold(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.deepPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menu clicked")),
              );
            },
          )
        ],
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
          }else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.compare), label: "Compare"),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: "Predictor"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "My Profile"),
        ],
      ),
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

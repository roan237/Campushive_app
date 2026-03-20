import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added this
import 'package:cloud_firestore/cloud_firestore.dart'; // Added this
import 'login.dart';
import 'main.dart';

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

  // --- NEW LOGIC STARTS HERE ---
  Future<void> _signup() async {
    String name = nameC.text.trim();
    String email = emailC.text.trim();
    String pass = passC.text.trim();
    String confirm = confirmC.text.trim();

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

    try {
      // 1. Create the user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      // 2. Get the Unique ID (UID) from Auth
      String uid = userCredential.user!.uid;

      // 3. Store the user profile in Firestore using that UID
      // Note: We DO NOT store the password here anymore.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
      });

      setState(() => loading = false);
      _showMsg("Signup successful ✅");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );

    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);

      // Better error handling for the user
      if (e.code == 'email-already-in-use') {
        _showMsg("This email is already registered.");
      } else if (e.code == 'weak-password') {
        _showMsg("The password provided is too weak.");
      } else {
        _showMsg(e.message ?? "An error occurred");
      }
    } catch (e) {
      setState(() => loading = false);
      _showMsg("Error: $e");
    }
  }
  // --- NEW LOGIC ENDS HERE ---

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
                const Text("Create An Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: loading ? null : _signup,
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    "SIGN UP",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
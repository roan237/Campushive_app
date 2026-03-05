import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ---------------- LOAD NAME + EMAIL ----------------
  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in ❌")),
      );
      return;
    }

    try {
      // Email from FirebaseAuth
      emailController.text = user!.email ?? "";

      // Name from Firestore
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        nameController.text = doc.data()?["name"] ?? "";
      } else {
        // If document doesn't exist, create it
        await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
          "name": user!.displayName ?? "",
          "email": user!.email ?? "",
        });

        nameController.text = user!.displayName ?? "";
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  // ---------------- SAVE CHANGES ----------------
  Future<void> _saveChanges() async {
    if (user == null) return;

    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();

    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Email cannot be empty")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ---------------- CHECK IF NEED REAUTH ----------------
      final bool emailChanged = newEmail != user!.email;
      final bool passwordChanging =
          newPass.isNotEmpty || confirmPass.isNotEmpty;

      if (emailChanged || passwordChanging) {
        if (oldPass.isEmpty) {
          throw "Enter old password to change email/password.";
        }

        final cred = EmailAuthProvider.credential(
          email: user!.email!,
          password: oldPass,
        );

        await user!.reauthenticateWithCredential(cred);
      }

      // ---------------- UPDATE EMAIL ----------------
      if (emailChanged) {
        await user!.updateEmail(newEmail);
      }

      // ---------------- UPDATE PASSWORD ----------------
      if (passwordChanging) {
        if (newPass.length < 6) {
          throw "New password must be at least 6 characters.";
        }
        if (newPass != confirmPass) {
          throw "Passwords do not match.";
        }

        await user!.updatePassword(newPass);
      }

      // ---------------- UPDATE FIRESTORE ----------------
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "name": newName,
        "email": newEmail,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👤 Profile Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _inputBox(
              controller: nameController,
              hint: "Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 12),

            _inputBox(
              controller: emailController,
              hint: "Email",
              icon: Icons.email,
            ),

            const SizedBox(height: 24),

            const Text(
              "🔒 Change Password",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _inputBox(
              controller: oldPasswordController,
              hint: "Old Password (only if changing email/password)",
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 12),

            _inputBox(
              controller: newPasswordController,
              hint: "New Password",
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 12),

            _inputBox(
              controller: confirmPasswordController,
              hint: "Confirm New Password",
              icon: Icons.lock,
              isPassword: true,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

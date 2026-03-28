import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollegeDetailsPage extends StatelessWidget {
  final String docId;

  const CollegeDetailsPage({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: const Text(
          "College Details",
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
        FirebaseFirestore.instance.collection("colleges").doc(docId).get(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong ❌"));
          }

          // No data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("College not found 😕"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // ✅ Fields from your screenshot
          final String name = (data["name"] ?? "No Name").toString();
          final String location = (data["location"] ?? "").toString();
          final String fees = (data["fees"] ?? "").toString();
          final String imageUrl = (data["imageUrl"] ?? "").toString();

          // Field has a space: "Placement Ratio"
          final String placementRatio =
          (data["Placement Ratio"] ?? "").toString();
          final String? type = data["type"]?.toString();
          final List courses =
          (data["courses"] is List) ? data["courses"] : [];
          final List contact = (data["contact"] is List) ? data["contact"] : [];



          // Courses array



          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------------- IMAGE ----------------
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: imageUrl.trim().isEmpty
                    ? Container(
                  height: 200,
                  color: Colors.deepPurple.shade100,
                  child: const Center(
                    child: Icon(Icons.school,
                        size: 90, color: Colors.deepPurple),
                  ),
                )
                    : Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.deepPurple.shade100,
                      child: const Center(
                        child: Icon(Icons.school,
                            size: 90, color: Colors.deepPurple),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- MAIN DETAILS CARD ----------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Location
                    if (location.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18, color: Colors.deepPurple),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    // Fees
                    if (fees.trim().isNotEmpty)
                      Text(
                        "Fees: $fees",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Placement Ratio
                    if (placementRatio.trim().isNotEmpty)
                      Text(
                        "Placement Ratio: $placementRatio",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 10), // Keeps the spacing consistent

                    // ✅ Added College Type here
                    if (type != null && type!.trim().isNotEmpty)
                      Text(
                        "College Type: ${type!.toUpperCase()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ---------------- COURSES CARD ----------------
              if (courses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Courses Offered",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: courses.map((course) {
                          final c = course as Map<String, dynamic>;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  c["Name"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text("Last Rank: ${c["last rank"] ?? "-"}"),

                                Text("Accreditation: ${c["accreditation"] ?? "-"}"),

                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              if (contact.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Contact Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Email (Index 0 in your screenshot)
                      if (contact.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 20, color: Colors.deepPurple),
                              const SizedBox(width: 10),
                              Text(contact[0].toString(), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),

                      // Phone (Index 1 in your screenshot)
                      if (contact.length > 1)
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 20, color: Colors.deepPurple),
                            const SizedBox(width: 10),
                            Text(contact[1].toString(), style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ---------------- FAVORITES BUTTON (UI ONLY) ----------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B1D6D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    // 2. Get the actual logged-in user
                    final User? user = FirebaseAuth.instance.currentUser;

                    // 3. Check if the user is logged in
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please login to save favorites! 🔑"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // 4. Use the real User ID (UID)
                    final String userId = user.uid;

                    try {
                      // Show a loading indicator or simple feedback
                      await FirebaseFirestore.instance
                          .collection("favorites")
                          .doc(userId) // Now saving to the unique user folder
                          .collection("colleges")
                          .doc(docId) // Uses the specific college document ID
                          .set({
                        "name": data["name"],
                        "location": data["location"],
                        "imageUrl": data["imageUrl"],
                        "addedAt": FieldValue.serverTimestamp(), // Useful for sorting by "recently added"
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to Favorites ❤️"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // This catches errors, like if your Security Rules block the request
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to add: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: const Text(
                    "Add to Favorites",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
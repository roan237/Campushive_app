import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_details.dart';

class ExploreCollegesPage extends StatelessWidget {
  final String? search;
  final String? location;
  final String? course;
  final int? maxFees;
  final int? minPlacement;
  final String? type; // Updated variable name

  const ExploreCollegesPage({
    super.key,
    this.search,
    this.location,
    this.course,
    this.maxFees,
    this.minPlacement,
    this.type, // Updated in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Explore Colleges",
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("colleges").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No colleges found"));
          }

          final docs = snapshot.data!.docs;
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // 1. Search Filter
            if (search != null && search!.isNotEmpty) {
              String name = (data["name"] ?? "").toString().toLowerCase();
              if (!name.contains(search!.toLowerCase())) {
                return false;
              }
            }

            // 2. Location Filter
            if (location != null && location!.isNotEmpty) {
              String loc = (data["location"] ?? "").toString().toLowerCase();
              if (!loc.contains(location!.toLowerCase())) {
                return false;
              }
            }

            // 3. Fees Filter
            if (maxFees != null) {
              int fees = data["fees"] ?? 0;
              if (fees > maxFees!) {
                return false;
              }
            }

            // 4. Placement Ratio Filter
            if (minPlacement != null) {
              int placement = data["Placement Ratio"] ?? 0;
              if (placement < minPlacement!) {
                return false;
              }
            }

            // 5. Course Filter (Nested List)
            if (course != null && course!.isNotEmpty) {
              List courses = data["courses"] ?? [];
              bool found = false;
              for (var c in courses) {
                String cname = (c["Name"] ?? "").toString().toLowerCase();
                if (cname.contains(course!.toLowerCase())) {
                  found = true;
                  break;
                }
              }
              if (!found) return false;
            }

            // 6. College Type Filter (Top-level document field)
            // This replaces the broken accreditation loop
            if (type != null && type!.isNotEmpty) {
              String collegeType = (data["type"] ?? "").toString().toLowerCase();
              if (collegeType != type!.toLowerCase()) {
                return false;
              }
            }

            return true;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text(
                "No colleges match your filters",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;
              return _collegeCard(
                context,
                filteredDocs[index].id,
                data["name"] ?? "",
                data["imageUrl"] ?? "",
                data["location"] ?? "",
              );
            },
          );
        },
      ),
    );
  }

  Widget _collegeCard(
      BuildContext context,
      String docId,
      String name,
      String imageUrl,
      String location,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isEmpty
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
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
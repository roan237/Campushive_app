import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_details.dart';

class ExploreCollegesPage extends StatelessWidget {
  final String? search;
  final String? location;
  final String? course;
  final int? maxFees;
  final int? minPlacement;
  final String? accreditation;

  const ExploreCollegesPage({
    super.key,
    this.search,
    this.location,
    this.course,
    this.maxFees,
    this.minPlacement,
    this.accreditation,
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

          final docs = snapshot.data!.docs;
          final filteredDocs = docs.where((doc) {

            final data = doc.data() as Map<String, dynamic>;

            if (search != null && search!.isNotEmpty) {
              if (!(data["name"] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(search!)) {
                return false;
              }
            }

            if (location != null && location!.isNotEmpty) {
              if (!(data["location"] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(location!)) {
                return false;
              }
            }

            if (maxFees != null) {
              if ((data["fees"] ?? 0) > maxFees!) {
                return false;
              }
            }

            if (minPlacement != null) {
              if ((data["Placement Ratio"] ?? 0) < minPlacement!) {
                return false;
              }
            }
            if (course != null && course!.isNotEmpty) {

              List courses = data["courses"] ?? [];

              bool found = false;

              for (var c in courses) {
                String cname = (c["Name"] ?? "").toString().toLowerCase();

                if (cname.contains(course!)) {
                  found = true;
                  break;
                }
              }

              if (!found) return false;
            }
            if (accreditation != null && accreditation!.isNotEmpty) {

              List courses = data["courses"] ?? [];

              bool match = false;

              for (var c in courses) {
                String acc = (c["accreditation"] ?? "").toString().toLowerCase();

                if (acc == accreditation) {
                  match = true;
                  break;
                }
              }

              if (!match) return false;
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
                filteredDocs[index].id,   // ✅ correct
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
            child: imageUrl.toString().isEmpty
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
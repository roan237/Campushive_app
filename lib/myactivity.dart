import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_details.dart';

class MyActivityPage extends StatelessWidget {
  const MyActivityPage({super.key});

  @override
  Widget build(BuildContext context) {

    const userId = "demoUser";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Activity",
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "⭐ Wishlist",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(

              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("favorites")
                    .doc(userId)
                    .collection("colleges")
                    .snapshots(),

                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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

                      child: Text(
                        "No colleges wishlisted yet 😄",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,

                    itemBuilder: (context, index) {

                      final data = docs[index].data();


                      return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollegeDetailsPage(
                              docId: docs[index].id,
                            ),
                          ),
                        );
                      },

                      child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),

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

                        child: Row(
                          children: [

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: data["imageUrl"] != null && data["imageUrl"] != ""
                                  ? Image.network(
                                data["imageUrl"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 60,
                                height: 60,
                                color: Colors.deepPurple.shade100,
                                child: const Icon(
                                  Icons.school,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    data["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    data["location"],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),

                              onPressed: () async {

                                await FirebaseFirestore.instance
                                    .collection("favorites")
                                    .doc(userId)
                                    .collection("colleges")
                                    .doc(docs[index].id)
                                    .delete();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Removed from wishlist ❌"),
                                  ),
                                );

                              },
                            )
                          ],
                        ),
                      ),);
                    },
                  );
                },
              ),
            ),






          ],
        ),
      ),
    );
  }
}
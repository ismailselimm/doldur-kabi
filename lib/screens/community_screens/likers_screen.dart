import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';

import '../../widgets/shimmer_avatar.dart';

class LikersScreen extends StatelessWidget {
  final List<String> likedBy;
  const LikersScreen({super.key, required this.likedBy});

  @override
  Widget build(BuildContext context) {
    // Firebase whereIn limiti
    final filteredLikedBy = likedBy.length > 10 ? likedBy.take(10).toList() : likedBy;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Beğenenler',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: likedBy.isEmpty
          ? Center(
        child: Text(
          "Henüz beğenen yok.",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      )
          : FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('email', whereIn: filteredLikedBy)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Kullanıcı bilgileri yüklenemedi.",
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final profileUrl = data['profileUrl'] ??
                  "https://cdn-icons-png.flaticon.com/512/847/847969.png";
              final userName =
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
              final userEmail = data['email'] ?? '';
              final userId = docs[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: userId,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ShimmerAvatar(imageUrl: profileUrl, radius: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userName.isEmpty ? "Kullanıcı" : userName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

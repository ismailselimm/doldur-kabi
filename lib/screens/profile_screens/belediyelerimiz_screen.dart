import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../home_screens/shelter_application_screen.dart';


class MunicipalitiesScreen extends StatelessWidget {
  const MunicipalitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        title: Text(
          'Belediyelerimiz',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
       /* actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30), // 👈 boyutu büyüttük
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShelterApplicationScreen()),
              );
            },
          ),
        ], */
      ),
      body: Container(
        color: const Color(0xFFFDF4FF),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('municipalities')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("Henüz belediye eklenmemiş.", style: TextStyle(color: Colors.grey)),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              itemCount: docs.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 🔥 İlk sıraya başlık ve açıklama
                  return Column(
                    children: [
                      const Text(
                        'Bizimle iş birliği yapan belediyeler sayesinde daha fazla cana ulaşabiliyoruz. Destekleri için teşekkür ederiz.',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Logolara tıklayarak belediyelerimizin \nwebsitelerini ziyaret edebilirsiniz.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                }

                final data = docs[index - 1].data() as Map<String, dynamic>;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      data['imageUrl'],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(height: 100, color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportersScreen extends StatelessWidget {
  const SupportersScreen({super.key});

  void _launchSponsorWebsite(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('URL açılamadı: $url');
    }
  }

  Widget _buildSponsorList(
      List<QueryDocumentSnapshot> docs,
      String category,
      Color borderColor,
      int crossAxisCount, // 🔥 kaç sütun olacak (elmas=1, altın=2, gümüş=3)
      double fontSize,
      double shadowOpacity,
      ) {
    final categorySponsors = docs.where((doc) {
      final docCategory = doc['category']?.toString().toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      final inputCategory = category.toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      return docCategory == inputCategory;
    }).toList();

    if (categorySponsors.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _getCategoryTitle(category),
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categorySponsors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5, // geniş dikdörtgen görünüm
          ),
          itemBuilder: (context, index) {
            final data = categorySponsors[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () => _launchSponsorWebsite(data['websiteUrl']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(shadowOpacity),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  data['imageUrl'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdSupporterGrid(List<QueryDocumentSnapshot> docs) {
    final adSponsors = docs.where((doc) {
      final cat = doc['category']?.toString().toLowerCase();
      return cat == 'reklam';
    }).toList();

    if (adSponsors.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "📣 Reklam Destekçilerimiz",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: adSponsors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // 🔁 Kare kutular
          ),
          itemBuilder: (context, index) {
            final data = adSponsors[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () => _launchSponsorWebsite(data['websiteUrl']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.deepPurple.shade100, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'Elmas':
        return '💎 Bu Ayın Elmas Destekçileri';
      case 'Altın':
        return '🥇 Bu Ayın Altın Destekçileri';
      case 'Gümüş':
        return '🥈 Bu Ayın Gümüş Destekçileri';
      default:
        return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FF),
      appBar: AppBar(
        title: Text(
          'Destekçilerimiz',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('supporters')
            .orderBy('createdAt', descending: true)
            .get(), // 🔁 burada tek seferlik veri çekiliyor
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.purple),
                  const SizedBox(height: 16),
                  Text("Destekçiler yükleniyor...", style: GoogleFonts.poppins()),
                ],
              ),
            );
          }


          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Uygulamamıza destek veren tüm markalara teşekkür ederiz. Sayelerinde daha fazla patili dosta ulaşıyoruz.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Logolara tıklayarak destekçilerimizin (varsa) websitelerini ziyaret edebilirsiniz.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _buildSponsorList(docs, 'Elmas', Colors.cyan.shade700, 1, 20, 0.4),
                _buildSponsorList(docs, 'Altın', Colors.amber.shade700, 2, 18, 0.3),
                _buildSponsorList(docs, 'Gümüş', Colors.grey.shade600, 3, 18, 0.2),

                _buildAdSupporterGrid(docs),

                const SizedBox(height: 30),

                InkWell(
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'ismailselimgarip@gmail.com',
                      query: Uri.encodeFull(
                        'subject=Destek Olmak İstiyorum&body=Merhaba,\n\nDoldurKabı uygulamasına destek olmak istiyoruz. Detayları konuşabilir miyiz?\n\nSaygılarımızla,',
                      ),
                    );

                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    } else {
                      debugPrint('Mail uygulaması açılamadı.');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.deepPurple.withOpacity(0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9346A1), Color(0xFFE970A4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          "Destek Olmak İster Misiniz?",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

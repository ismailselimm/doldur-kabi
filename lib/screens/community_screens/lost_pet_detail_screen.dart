import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/report_dialog.dart';


class LostPetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pet;

  const LostPetDetailScreen({super.key, required this.pet});

  @override
  State<LostPetDetailScreen> createState() => _LostPetDetailScreenState();
}

class _LostPetDetailScreenState extends State<LostPetDetailScreen> {
  late final List imageUrls;
  late final String name, type, location, description, emoji;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    imageUrls = widget.pet['imageUrls'] ?? [];
    name = widget.pet['petName'] ?? "Bilinmeyen";
    type = widget.pet['petType'] ?? "";
    location = widget.pet['location'] ?? "Bilinmiyor";
    description = widget.pet['description'] ?? "";
    emoji = type == "Kedi" ? "🐱" : type == "Köpek" ? "🐶" : "🐦";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: imageUrls.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImagePopup(context, imageUrls.cast<String>(), index),
                        child: Hero(
                          tag: 'lostPetImage$index',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                            ),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;

                                // SHIMMER efekti geliyor şimdi 🔥
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_currentIndex + 1}/${imageUrls.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST BİLGİ - İSİM VE TÜR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol taraf: isim + rozet
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "$emoji $name",
                                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    type,
                                    style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.deepPurple),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "📍 $location",
                              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14.5),
                            ),
                          ],
                        ),
                      ),

                      // Sağ taraf: paylaş & bildir ikonları
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.flag_outlined, color: Colors.black),
                            tooltip: "İlanı bildir",
                            onPressed: () async {
                              final data = widget.pet;
                              final addedByUid = data['userId'] ?? data['addedBy'];
                              final targetUserEmail = addedByUid != null
                                  ? (await _getEmailFromUid(addedByUid)) ?? 'unknown@doldurkabi.com'
                                  : 'unknown@doldurkabi.com';

                              if (addedByUid == null || targetUserEmail.isEmpty || data['id'] == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Eksik veri nedeniyle bildirilemedi."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              showReportDialog(
                                context,
                                targetType: 'Kayıp Hayvan İlanı',
                                targetId: data['id'],
                                targetUserEmail: targetUserEmail,
                                targetTitle: data['petName'] ?? 'Kayıp Hayvan',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.black87),
                            tooltip: "İlanı paylaş",
                            onPressed: () {
                              final id = widget.pet['id'];
                              final description = widget.pet['description'] ?? '';
                              final name = widget.pet['petName'] ?? '';
                              final shareLink = 'https://doldurkabi.com/lost/$id';

                              final shareText = '''
🚨 Kayıp Hayvan İlanı

🐾 Adı: $name
📍 Konum: $location
📝 Açıklama: $description

🔗 Detaylar: $shareLink
''';

                              Share.share(shareText);
                            },

                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (description.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '"$description"',
                        style: GoogleFonts.poppins(fontSize: 15.5, height: 1.6, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gördüysen hemen ara!",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bu dostumuz kayıp. Eğer bir yerde gördüyseniz, lütfen sahibine haber verin. 🙏",
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(widget.pet['phone'] ?? ""),
                            icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                            label: Text(
                              "Ara",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePopup(BuildContext context, List<String> imageUrls, int initialIndex) {
    PageController controller = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // 📸 GÖRSELLER
                  PageView.builder(
                    controller: controller,
                    itemCount: imageUrls.length,
                    onPageChanged: (index) => setState(() => currentIndex = index),
                    itemBuilder: (context, index) {
                      return Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 1,
                          maxScale: 4,
                          child: Hero(
                            tag: 'lostPetImage$index',
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ❌ KAPATMA
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ),

                  // 🔘 DOTS
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(imageUrls.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentIndex == index ? 10 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: currentIndex == index ? Colors.purpleAccent : Colors.white54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    ),

                  // 📄 SAYFA SAYACI
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 38,
                      right: 20,
                      child: Text(
                        "${currentIndex + 1}/${imageUrls.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // İsteğe bağlı: kullanıcıya hata bildir
      debugPrint("Arama yapılamıyor: $phoneNumber");
    }
  }

  Future<String?> _getEmailFromUid(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();
      return userData?['email'] as String?;
    } catch (e) {
      print("❌ UID'den e-posta alınamadı: $e");
      return null;
    }
  }
}

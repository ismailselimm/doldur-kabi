import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:doldur_kabi/screens/profile_screens/chat_screen.dart';
import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';
import 'package:doldur_kabi/widgets/banner_widget.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/shimmer_avatar.dart';
import 'adoption_poster_screen.dart';

class AdoptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> adoptData;
  final String docId;


  const AdoptionDetailScreen({
    super.key,
    required this.adoptData,
    required this.docId, // ✅ EKLE
  });


  String _getRelativeDate(Timestamp? timestamp) {
    if (timestamp == null) return "Tarih yok";

    final now = DateTime.now();
    final postDate = timestamp.toDate();
    final difference = now.difference(postDate).inDays;

    if (difference == 0) return "Bugün";
    if (difference == 1) return "Dün";
    if (difference <= 30) return "$difference gün önce";
    return "${postDate.day.toString().padLeft(2, '0')}.${postDate.month.toString().padLeft(2, '0')}.${postDate.year}";
  }

  Widget _buildSquareActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = adoptData['imageUrl'] ?? '';
    final String description = adoptData['description'] ?? 'Açıklama yok';
    final String animalType = adoptData['animalType'] ?? '';
    final String city = adoptData['city'] ?? '';
    final Timestamp? timestamp = adoptData['timestamp'];
    final String ownerId = adoptData['ownerId'] ?? '';
    final String ownerName = adoptData['ownerName'] ?? 'Kullanıcı';
    final String profileUrl = adoptData['ownerProfileUrl'] ?? '';
    final String ownerEmail = adoptData['ownerEmail'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "Görsel",
                    barrierColor: Colors.black.withOpacity(1), // Arka planı bulanık gibi yapar
                    transitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (context, anim1, anim2) {
                      return SafeArea(
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Stack(
                            children: [
                              Center(
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 1,
                                  maxScale: 4,
                                  child: Hero(
                                    tag: 'adoptionImage',
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Hero(
                  tag: 'adoptionImage',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Açıklama kutusu
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
                      description,
                      style: GoogleFonts.poppins(fontSize: 15.5, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bilgi kartları
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildInfoCard(
                        title: "Hayvan Türü",
                        value: animalType,
                        icon: FontAwesomeIcons.paw,
                        color: Colors.orange,
                      ),
                      _buildInfoCard(
                        title: "Şehir",
                        value: city,
                        icon: Icons.location_on,
                        color: Colors.pinkAccent,
                      ),
                      _buildInfoCard(
                        title: "İlan Tarihi",
                        value: _getRelativeDate(timestamp),
                        icon: FontAwesomeIcons.calendarDay,
                        color: Colors.deepPurpleAccent,
                      ),
                      const SizedBox(height: 1),

                    ],
                  ),

                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdoptionPosterScreen(
                              imageUrl: imageUrl,
                              description: description,
                              animalType: animalType,
                              city: city,
                              date: timestamp?.toDate(),
                              ownerName: ownerName,
                              docId: docId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 20, color: Color(0xFF9346A1)),
                      label: Text(
                        "Afişi Görüntüle / İndir",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9346A1),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // İlan Sahibi ve mesaj butonu
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: ownerId,
                                userEmail: ownerEmail,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            (profileUrl.isNotEmpty)
                                ? ShimmerAvatar(imageUrl: profileUrl, radius: 24)
                                : const CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage('assets/images/avatar1.png'),
                            ),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                _getCleanSmartName(ownerName),
                                style: GoogleFonts.poppins(fontSize: 15.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Mesaj ikonu
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0), // daha içeri hizalı
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSquareActionIcon(
                              icon: FontAwesomeIcons.paperPlane,
                              onTap: () {
                                if (ownerEmail.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(receiverEmail: ownerEmail),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildSquareActionIcon(
                              icon: FontAwesomeIcons.shareNodes,
                              onTap: () {
                                final shareLink = 'https://doldurkabi.com/adoption/$docId';
                                final shareText = '''
🐾 Bu hayvanı sahiplenmek ister misin?

📌 Açıklama: $description

🔗 Detaylar: $shareLink
''';

                                Share.share(shareText);
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildSquareActionIcon(
                              icon: Icons.flag,
                              color: Colors.black,
                              onTap: () async {
                                await showReportDialog(
                                  context,
                                  targetId: docId,
                                  targetTitle: description,
                                  targetType: "Sahiplendirme İlanı",
                                  targetUserEmail: ownerEmail,
                                );
                              },
                            ),
                          ],
                        ),
                      ),



                    ],
                  ),
                ],
              ),
            ),
          ),


          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: const BannerWidget(),
            ),
          ),

        ],
      ),
    );
  }

  String _getCleanSmartName(String fullName) {
    List<String> parts = fullName.trim().split(' ');

    // İki kelimelik ve her biri 8 karakterden kısa ise direkt göster
    if (parts.length == 2 && parts[0].length <= 8 && parts[1].length <= 8) {
      return fullName;
    }

    // Uzunsa soyadın sadece ilk harfini göster
    if (parts.length >= 2) {
      String isimler = parts.sublist(0, parts.length - 1).join(' ');
      String soyadIlkHarf = parts.last[0];
      return "$isimler ${soyadIlkHarf.toUpperCase()}.";
    }

    return fullName;
  }




  Widget _buildInfoCard({required String title, required String value, required IconData icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? Colors.deepPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

}

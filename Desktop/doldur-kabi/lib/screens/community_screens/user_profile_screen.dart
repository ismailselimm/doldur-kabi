import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:doldur_kabi/screens/profile_screens/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const UserProfileScreen({super.key, required this.userId, required this.userEmail});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F9),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text("DoldurKabı Profili",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;

          int mamaDoldurma = data['mamaDoldurmaSayisi'] ?? 0;
          int beslemeKabi = data['beslemeNoktasiSayisi'] ?? 0;
          int hayvanEvi = data['hayvanEviSayisi'] ?? 0;
          int gonderiSayisi = data['gonderiSayisi'] ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (data['profileUrl'] != null && data['profileUrl'].toString().isNotEmpty) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => FullScreenImage(imageUrl: data['profileUrl']),
                            ),
                          );
                        }
                      },
                      child: Hero(
                        tag: 'profileImage_${data['uid'] ?? widget.userId}',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: ClipOval(
                            child: Image.network(
                              data['profileUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const CircularProgressIndicator();
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/images/avatar1.png');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${data['firstName']} ${data['lastName']}",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(data['email'],
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.paperPlane, color: Colors.black),
                      onPressed: () {
                        final email = data['email'] ?? '';
                        if (email.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(receiverEmail: email)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              _buildMiniStatsRow(
                mamaDoldurma,
                beslemeKabi,
                hayvanEvi,
                gonderiSayisi,
              ),

              const SizedBox(height: 16),

              /// 🔥 ARTIK BURADA: TABBAR
              Align(
                alignment: Alignment.center,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF9346A1),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: FaIcon(FontAwesomeIcons.image)),          // Gönderiler
                    Tab(icon: FaIcon(FontAwesomeIcons.paw)),            // Sahiplendirme
                    Tab(icon: FaIcon(FontAwesomeIcons.exclamationTriangle)), // Kayıp
                  ],
                ),
              ),

              const Divider(height: 0),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserContentList("posts", widget.userId, "description", "imageUrl"),
                    _buildUserContentList("adoption_posts", widget.userId, "description", "imageUrl", idField: "ownerId"),
                    _buildUserContentList("lost_pets", widget.userId, "petName", "imageUrl"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }




  Widget _buildUserContentList(String collection, String userId, String contentField, String imageField,
      {String idField = 'userId'}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where(idField, isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("Henüz içerik yok.", style: TextStyle(color: Colors.grey)));
        }

        return GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (collection == "adoption_posts") {
              return buildAdoptionGridItem(context, data);
            } else if (collection == "lost_pets") {
              return buildLostPetGridItem(context, data);
            } else {
              final imageUrl = data[imageField] ?? "";
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(
                        imageUrl: data['imageUrl'],
                        description: data['description'] ?? "",
                        userName: data['username'] ?? "Bilinmeyen",
                        profileUrl: data['userImage'] ?? "",
                        timestamp: data['createdAt'],
                        likes: data['likes'] ?? 0,
                        comments: data['comments'] ?? 0,
                      ),
                    ),
                  );
                },

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildMiniStatsRow(int mama, int kabi, int ev, int gonderi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol başlık
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(" DoldurKabı", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("   Analizleri", style: GoogleFonts.poppins(fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),

          // Aradaki ":"
          const Text(":", style: TextStyle(fontSize: 18)),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(FontAwesomeIcons.bowlFood, mama, Colors.black87),
                _buildStatItem(FontAwesomeIcons.paw, kabi, Colors.black87),
                _buildStatItem(FontAwesomeIcons.houseChimney, ev, Colors.black87),
                _buildStatItem(FontAwesomeIcons.image, gonderi, Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }



}

// 🔥 Sahiplendirme için grid item
Widget buildAdoptionGridItem(BuildContext context, Map<String, dynamic> data) {
  return GestureDetector(
    onTap: () => _showAdoptionDetail(context, data),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        data['imageUrl'],
        fit: BoxFit.cover,
      ),
    ),
  );
}


// 🔥 Sahiplendirme detay sayfası
void _showAdoptionDetail(BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (_) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.deepPurple, child: const Icon(Icons.pets, color: Colors.white)),
              const SizedBox(width: 10),
              Text(data['ownerName'] ?? "Kullanıcı", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(data['imageUrl'], fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(data['description'] ?? "-", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text("Şehir: ${data['city'] ?? "-"}", style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 13)),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// 🔥 Kayıp ilanı için grid item
Widget buildLostPetGridItem(BuildContext context, Map<String, dynamic> data) {
  return GestureDetector(
    onTap: () => _showLostPetDetail(context, data),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        data['imageUrl'],
        fit: BoxFit.cover,
      ),
    ),
  );
}


// 🔥 Kayıp detay sayfası
void _showLostPetDetail(BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (_) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.redAccent, child: const Icon(Icons.report, color: Colors.white)),
              const SizedBox(width: 10),
              Text(data['petName'] ?? "Kayıp Hayvan", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(data['imageUrl'], fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text("Tür: ${data['petType'] ?? "-"}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          Text("Konum: ${data['location'] ?? "-"}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text("İletişim: ${data['phone'] ?? "-"}", style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 13)),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}


class PostDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String description;
  final String userName;
  final String profileUrl;
  final Timestamp? timestamp;
  final int likes;
  final int comments;


  const PostDetailScreen({
    super.key,
    required this.imageUrl,
    required this.description,
    required this.userName,
    required this.profileUrl,
    required this.likes,
    required this.comments,
    this.timestamp,
  });


  @override
  Widget build(BuildContext context) {
    final formattedDate = timestamp != null
        ? "${timestamp!.toDate().day}.${timestamp!.toDate().month}.${timestamp!.toDate().year}"
        : "";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst: profil info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileUrl),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                          color: Colors.grey[400], fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Fotoğraf
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),

          // Açıklama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),

          // Beğeni ve yorum satırı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white, size: 30),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                const SizedBox(width: 16),
                const Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 24),
                const Spacer(),
                const Icon(Icons.bookmark_border, color: Colors.white, size: 32),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$likes beğeni • $comments yorum",
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // **1️⃣ Arka planı bulanıklaştırma, uygulama görünür kalacak**
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur efekti
            child: Container(
              color: Colors.black.withOpacity(0.2), // Hafif karartma efekti
            ),
          ),
        ),

        // **2️⃣ Tam ekran fotoğrafı (DAHA BÜYÜK DAİRE)**
        Center(
          child: Hero(
            tag: 'profileImage',
            child: ClipOval( // 🔥 Fotoğrafı daire yapıyor
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 300, // 📌 Daha büyük daire (300x300 yapıldı)
                height: 300, // 📌 Daha büyük daire
                fit: BoxFit.cover, // Daireye sığdır
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),

        // **3️⃣ Sağ üstte kapatma butonu**
        Positioned(
          top: 70,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}

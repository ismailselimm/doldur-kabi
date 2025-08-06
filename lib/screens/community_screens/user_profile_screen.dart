import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:doldur_kabi/screens/profile_screens/chat_screen.dart';
import 'package:shimmer/shimmer.dart';

import '../../widgets/report_dialog.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const UserProfileScreen({super.key, required this.userId, required this.userEmail});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int totalUserPosts = 0;
  int adoptedCount = 0;
  int adoptedByUserCount = 0;
  bool showMessageButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTotalUserPosts();
    _fetchAdoptedCount();
    _fetchAdoptedByUserCount();
    _checkIfUserHasContent(); // 👈 ekledik

  }

  void _checkIfUserHasContent() async {
    final adoptionSnap = await FirebaseFirestore.instance
        .collection('adoption_posts')
        .where('ownerId', isEqualTo: widget.userId)
        .get();

    final lostSnap = await FirebaseFirestore.instance
        .collection('lost_pets')
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (mounted) {
      setState(() {
        showMessageButton = adoptionSnap.docs.isNotEmpty || lostSnap.docs.isNotEmpty;
      });
    }
  }


  void _fetchAdoptedByUserCount() async {
    String emailToUse = widget.userEmail;

    // Email boşsa userId üzerinden al
    if (emailToUse.isEmpty) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      emailToUse = userData?['email'] ?? '';
    }

    if (emailToUse.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('adoptionRecords')
          .where('receiverUserId', isEqualTo: emailToUse)
          .get();

      if (mounted) {
        setState(() {
          adoptedByUserCount = snapshot.docs.length;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9346A1),
        title: Text("DoldurKabı Profili",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0), // ← sağdan 8px içeride
            child: GestureDetector(
              onTap: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen giriş yapın.")),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: const Icon(Icons.flag, color: Colors.redAccent),
                            title: const Text("Bu kullanıcıyı bildir"),
                            onTap: () async {
                              Navigator.pop(context);
                              await showReportDialog(
                                context,
                                targetId: widget.userId,
                                targetType: "Kullanıcı",
                                targetUserEmail: widget.userEmail,
                                targetTitle: "${widget.userEmail} profili",
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Icon(Icons.more_vert, size: 22),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🔹 Ana içerik aynı kalsın
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final data = snapshot.data!.data() as Map<String, dynamic>;

              int mamaDoldurma = data['mamaDoldurmaSayisi'] ?? 0;
              int beslemeKabi = data['beslemeNoktasiSayisi'] ?? 0;
              int hayvanEvi = data['hayvanEviSayisi'] ?? 0;
              int totalUserPosts = this.totalUserPosts;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
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
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: NetworkImage(data['profileUrl'] ?? ''),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${data['firstName']} ${data['lastName']}",
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("DoldurKabı Skorları",
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildImageStatItem('assets/images/doldurma.png', mamaDoldurma, Colors.black87),
                                  const SizedBox(width: 20),
                                  _buildImageStatItem('assets/images/boskap.png',beslemeKabi, Colors.black87),
                                  const SizedBox(width: 20),
                                  _buildStatItem(FontAwesomeIcons.houseChimney, hayvanEvi, Colors.black87),
                                  const SizedBox(width: 20),
                                  _buildStatItem(FontAwesomeIcons.image, totalUserPosts, Colors.black87),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),


                  if (adoptedByUserCount > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "${data['firstName']} ${data['lastName']}, DoldurKabı sayesinde $adoptedByUserCount can dostumuzu sahiplenerek onların hayatına umut oldu!  🩷",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),


                  if (adoptedCount > 0)
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5), // yumuşak mor ton
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            "${data['firstName']} ${data['lastName']}, DoldurKabı sayesinde $adoptedCount can dostumuzu sahiplendirerek onların sıcak bir yuvaya kavuşmasına katkı sağladı! 🩷",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            "* Yalnızca 'sahiplendirildi' olarak işaretlenen ilanlar sayılır.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.2, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),





                  Align(
                    alignment: Alignment.center,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF9346A1),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: FaIcon(FontAwesomeIcons.image)),
                        Tab(icon: FaIcon(FontAwesomeIcons.paw)),
                        Tab(icon: FaIcon(FontAwesomeIcons.exclamationTriangle)),
                      ],
                    ),
                  ),

                  const Divider(height: 0),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUserContentList("posts", widget.userId, "description", "imageUrl"),
                        _buildUserContentList("adoption_posts", widget.userId, "description", "imageUrl", idField: "ownerId", filterApproved: true),
                        _buildUserContentList("lost_pets", widget.userId, "petName", "imageUrl", filterApproved: true),

                      ],
                    ),

                  ),
                ],
              );
            },

          ),
        ],
      ),

      floatingActionButton: showMessageButton &&
          FirebaseAuth.instance.currentUser?.uid != widget.userId
          ? Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 8),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final email = widget.userEmail;

            if (email.isEmpty) {
              final snapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .get();

              final data = snapshot.data() as Map<String, dynamic>?;
              final fetchedEmail = data?['email'];

              if (fetchedEmail != null && fetchedEmail.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(receiverEmail: fetchedEmail),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                      Text("Kullanıcının e-posta bilgisi bulunamadı.")),
                );
              }
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(receiverEmail: email),
                ),
              );
            }
          },
          backgroundColor: Colors.black,
          label: Row(
            children: [
              const Icon(FontAwesomeIcons.paperPlane,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                "Mesaj Gönder",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      )
          : null,



    );

  }

  void _fetchAdoptedCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('adoption_posts')
        .where('ownerId', isEqualTo: widget.userId)
        .where('isAdopted', isEqualTo: true)
        .get();

    if (mounted) {
      setState(() {
        adoptedCount = snapshot.docs.length;
      });
    }
  }


  void _fetchTotalUserPosts() async {
    int total = 0;
    final userId = widget.userId;

    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();
    total += posts.size;

    final adoptions = await FirebaseFirestore.instance
        .collection('adoption_posts')
        .where('ownerId', isEqualTo: userId)
        .get();
    total += adoptions.size;

    final losts = await FirebaseFirestore.instance
        .collection('lost_pets')
        .where('userId', isEqualTo: userId)
        .get();
    total += losts.size;

    if (mounted) {
      setState(() {
        totalUserPosts = total;
      });
    }
  }


  Widget _buildUserContentList(
      String collection,
      String userId,
      String contentField,
      String imageField, {
        String idField = 'userId',
        bool filterApproved = false, // 🔥 eklendi
      }) {
    // ✅ Sorguyu dışarıda hazırla
    Query query = FirebaseFirestore.instance
        .collection(collection)
        .where(idField, isEqualTo: userId);

    if (filterApproved) {
      query = query.where('isApproved', isEqualTo: true); // 🔥 onay filtrelemesi
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: const CircleAvatar(radius: 50, backgroundColor: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 15,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("Henüz içerik yok.", style: TextStyle(color: Colors.grey)));
        }

        return GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: docs.reversed.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (collection == "adoption_posts") {
              return buildAdoptionGridItem(context, data);
            } else if (collection == "lost_pets") {
              return buildLostPetGridItem(context, data);
            } else {
              String imageUrl = "";
              if (collection == "posts") {
                final List urls = data['imageUrls'] ?? [];
                imageUrl = urls.isNotEmpty ? urls.first : "";
              } else {
                imageUrl = data[imageField] ?? "";
              }
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnifiedDetailScreen(
                        imageUrl: imageUrl,
                        description: data['description'],
                        userId: data['userId'],
                        timestamp: data['createdAt'],
                        likes: data['likes'],
                        comments: data['comments'],
                        userName: data['username'],
                        profileUrl: data['userImage'],
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image))),
                    ),

                    if (collection == "posts" && (data['imageUrls']?.length ?? 0) > 1)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "📷 ${data['imageUrls'].length}",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
          }).toList(),
        );
      },
    );
  }




  Widget _buildImageStatItem(String assetPath, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          width: 30,
          child: Image.asset(
            assetPath,
            color: color,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          width: 30,
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            fontSize: 15,
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
  final bool isAdopted = data['isAdopted'] == true;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedDetailScreen(
            imageUrl: data['imageUrl'] ?? '',
            description: data['description'] ?? '',
            userId: data['ownerId'] ?? '',
            city: data['city'],
            isAdopted: data['isAdopted'] == true, // 👈 buraya dikkat
            timestamp: data['timestamp'], // ✅ BURASI ÖNEMLİ


          ),
        ),
      );
    },
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            data['imageUrl'],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        if (isAdopted)
          if (isAdopted)
            Positioned(
              top: 90,
              right: 0,
                child: Container(
                  width: 90,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: Colors.green.shade600,
                  child: const Text(
                    "Sahiplendirildi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ],
    ),
  );
}

// 🔥 Kayıp ilanı için grid item
Widget buildLostPetGridItem(BuildContext context, Map<String, dynamic> data) {
  List<dynamic> imageUrls = data['imageUrls'] ?? [];
  String imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : "";

  return GestureDetector(
      onTap: () {
        final imageUrl = (data['imageUrls'] as List?)?.first ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedDetailScreen(
              imageUrl: imageUrl,
              description: data['petName'] ?? '',
              userId: data['userId'],
              city: data['location'],
              phone: data['phone'],
              timestamp: data['timestamp'], // ✅ BURASI ÖNEMLİ

            ),
          ),
        );
      },

      child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, size: 40)),
      ),
    ),
  );
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

void showUnifiedContentDetail(
    BuildContext context, {
      required String imageUrl,
      required String description,
      required String userId,
      String? userName,
      String? profileUrl,
      Timestamp? timestamp,
      int? likes,
      int? comments,
      String? city,
      String? phone,
      bool? isAdopted, // 🔥 burayı ekledik
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final displayName = (userData?['firstName'] ?? '') + ' ' + (userData?['lastName'] ?? '');
        final profile = userData?['profileUrl'] ?? profileUrl ?? "";
        final nameToShow = displayName.trim().isNotEmpty ? displayName.trim() : (userName ?? "Kullanıcı");
        final date = timestamp != null
            ? "${timestamp.toDate().day}.${timestamp.toDate().month}.${timestamp.toDate().year}"
            : "";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16).add(
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                        backgroundColor: Colors.deepPurple,
                        child: profile.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nameToShow,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                          if (date.isNotEmpty)
                            Text(date,
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[400], fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),

                ],
              ),

              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(description,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 10),
              if (likes != null || comments != null)
                Text(
                  "${likes ?? 0} beğeni • ${comments ?? 0} yorum",
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                ),
              if (city != null)
                Text("Şehir: $city",
                    style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 13)),
              if (phone != null)
                Text("İletişim: $phone",
                    style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 13)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}


class UnifiedDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String description;
  final String userId;
  final String? userName;
  final String? profileUrl;
  final Timestamp? timestamp;
  final int? likes;
  final int? comments;
  final String? city;
  final String? phone;
  final bool isAdopted;



  const UnifiedDetailScreen({
    super.key,
    required this.imageUrl,
    required this.description,
    required this.userId,
    this.userName,
    this.profileUrl,
    this.timestamp,
    this.likes,
    this.comments,
    this.city,
    this.phone,
    this.isAdopted = false,

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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final String postId; // 👈 adoption_posts doküman ID'si
          final name = (data?['firstName'] ?? '') + ' ' + (data?['lastName'] ?? '');
          final nameToShow = name.trim().isNotEmpty ? name.trim() : (userName ?? "Kullanıcı");
          final avatarUrl = data?['profileUrl'] ?? profileUrl ?? "";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Bilgi
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            backgroundColor: Colors.deepPurple,
                            child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nameToShow,
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                                ],
                          ),
                        ],
                      ),

                      // ✅ SAHİPLENDİRİLDİ ETİKETİ
                      if (isAdopted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Sahiplendirildi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Görsel
                // Görsel kısmı
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImageViewer(imageUrl),
                ),

                // Açıklama
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                ),

                // Beğeni ve yorum
                if (likes != null || comments != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${likes ?? 0} beğeni • ${comments ?? 0} yorum",
                      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),


                // Tarih
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("İlan Tarihi: $formattedDate",
                      style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 12)),
                ),

                // Şehir
                if (city != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Şehir: $city",
                        style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 13)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    List<String> imageUrls;

    // Eğer virgülle ayrılmışsa çoklu resim, değilse tekli
    if (imageUrl.contains(",")) {
      imageUrls = imageUrl.split(",").map((e) => e.trim()).toList();
    } else {
      imageUrls = [imageUrl];
    }

    if (imageUrls.length > 1) {
      return SizedBox(
        height: 300,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return Stack(
              alignment: Alignment.bottomRight,
              children: [
                Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${index + 1} / ${imageUrls.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      );
    } else {
      return Image.network(imageUrls.first, fit: BoxFit.cover);
    }
  }

}

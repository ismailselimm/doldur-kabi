import 'package:doldur_kabi/screens/community_screens/adopt_pet_screen.dart';
import 'package:doldur_kabi/screens/community_screens/community_screen.dart';
import 'package:doldur_kabi/screens/community_screens/lost_pets_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../widgets/empty_state_widget.dart'; // Yeni ikonlar için


class IlanlarimScreen extends StatefulWidget {
  @override

  _IlanlarimScreenState createState() => _IlanlarimScreenState();
}

class _IlanlarimScreenState extends State<IlanlarimScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Paylaşımlarım",
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Gönderiler"),
            Tab(text: "Sahiplendirme"),
            Tab(text: "Kayıp İlanları"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          // ✅ Kullanıcının gönderilerini gösteriyor
          _buildAdoptionsTab(),
          // ✅ Kullanıcının sahiplendirme ilanlarını gösterecek
          _buildLostPetsTab(),
          // ✅ Kayıp hayvan ilanlarını gösterecek!
        ],
      ),

    );
  }

  Widget _buildLostPetsTab() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    print("🔍 Aktif UID: ${currentUser?.uid ?? 'Kullanıcı yok'}");

    if (currentUser == null) {
      return const Center(child: Text("Lütfen giriş yapın."));
    }

    Query query = _firestore.collection('lost_pets')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("❌ Firestore Hatası: ${snapshot.error}");
          return Center(
              child: Text("Veri çekilirken hata oluştu: ${snapshot.error}"));
        }

        // 🔥 Eğer veri yoksa boş mesaj göster
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: EmptyStateWidget(
              title: "İyi ki hiçbir patili dostun kaybolmamış 🐶💕",
              buttonText: "Kaybolursa tıkla buluruz",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LostPetsScreen()),
                );
              },
            ),
          );
        }



        var lostPets = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: lostPets.map((doc) {
            var postData = doc.data() as Map<String, dynamic>?;

            // 🔥 Eğer veri null ise atlamasını sağla
            if (postData == null) {
              print("⚠️ Boş veri bulundu, atlanıyor...");
              return const SizedBox.shrink();
            }

            return _buildLostPetCard(
              context,
              postId: doc.id,
              petType: postData['petType'] ?? "Bilinmeyen",
              petName: postData['petName'] ?? "Bilinmeyen",
              ownerName: "Siz",
              city: postData['city'] ?? "Bilinmeyen Şehir",
              description: postData['description'] ?? "Açıklama yok.",
              postRef: doc.reference,
              imageUrls: List<String>.from(
                  postData['imageUrls'] ?? []), // 💥 EKLE BUNU
            );
          }).toList(),
        );
      },
    );
  }


  Widget _buildLostPetCard(
      BuildContext context, {
        required String postId,
        required String petType,
        required String petName,
        required String ownerName,
        required String city,
        required String description,
        required DocumentReference postRef,
        required List<String> imageUrls,
      }) {
    String firstImage = imageUrls.isNotEmpty ? imageUrls[0] : "";
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final updatedImage = userData?['profileUrl'] ?? "";
        final updatedName = "${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}".trim();
        final nameToShow = updatedName.isNotEmpty ? updatedName : ownerName;

        return Card(
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: updatedImage.isNotEmpty
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(updatedImage),
                    radius: 20,
                  )
                      : const CircleAvatar(
                    child: Icon(Icons.person),
                    radius: 20,
                  ),
                  title: Text(
                    petName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "$petType • $city\nİlan Sahibi: $nameToShow",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.black),
                        onPressed: () {
                          _editLostPetPost(context, postId, description);
                        },
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22),
                        onPressed: () {
                          _deleteLostPetPost(context, postRef);
                        },
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 1, // 🔄 1:1 kare görünüm istersen
                    child: Image.network(
                      firstImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
                if (description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      '"$description"',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildAdoptionsTab() {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Lütfen giriş yapın."));
    }

    Query query = _firestore.collection('adoption_posts')
        .where('ownerEmail', isEqualTo: currentUser.email)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Veri çekilirken hata oluştu: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: EmptyStateWidget(
              title: "Minnoşları sahiplendirmek seninle başlasın \nHadi ilk ilanı ver! 🐾",
              buttonText: "İlan Ver",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdoptionScreen()), // ekranına göre değiştir
                );
              },
            ),
          );
        }


        // 🔧 Bu kısımda isAdopted değerini de debug etmek için log ekle
        var posts = snapshot.data!.docs;
        for (var post in posts) {
          var postData = post.data() as Map<String, dynamic>;
          print("🐾 Post: ${post.id} | isAdopted: ${postData['isAdopted']}");
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index];
            var postData = post.data() as Map<String, dynamic>;

            return _buildAdoptionCard(
              context,
              postId: post.id,
              animalType: postData['animalType'] ?? "Bilinmeyen",
              ownerName: postData['ownerName'] ?? "Bilinmeyen Kullanıcı",
              city: postData['city'] ?? "Bilinmeyen Şehir",
              imageUrl: postData['imageUrl'] ?? "",
              description: postData['description'] ?? "",
              postRef: post.reference,
              isAdopted: postData['isAdopted'] ?? false, // 🔥 Sahiplendirme bilgisi
            );
          },
        );
      },
    );
  }

  /// **🔥 Kullanıcının Paylaştığı Gönderileri Firebase’den Çekiyoruz**
  Widget _buildPostsTab() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Lütfen giriş yapın."));
    }

    // Kullanıcının gönderilerini çekiyoruz
    Query query = _firestore.collection('posts')
        .where(
        'userId', isEqualTo: currentUser.uid) // SADECE kullanıcının postları
        .orderBy('createdAt', descending: true);

    print("📡 [DEBUG] Firestore'dan veri çekmeye çalışıyorum...");

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(), // 🔥 Direkt stream ile dinleme yapıyoruz
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("❌ [HATA] Firebase Hatası: ${snapshot.error}");
          return Center(
            child: Text(
              "Veri çekilirken hata oluştu: ${snapshot.error}",
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: EmptyStateWidget(
              title: "Buralar senden sorulmaz mıydı? 👀\nBir gönderi at da sesin gelsin!",
              buttonText: "Gönderi Paylaş",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CommunityScreen()), // ekranına göre değiştir
                );
              },
            ),
          );
        }



        var posts = snapshot.data!.docs;
        print("✅ [DEBUG] ${posts.length} adet gönderi bulundu.");

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index];
            var postData = post.data() as Map<String, dynamic>;

            print("📌 [DEBUG] Post ID: ${post
                .id}, 📝 Açıklama: ${postData['description']}");

            final List imageUrls = postData['imageUrls'] ?? [];
            final String postImage = imageUrls.isNotEmpty ? imageUrls.first : "";

            return _buildPostCard(
              context,
              postId: post.id,
              username: postData['username'] ?? "Bilinmeyen Kullanıcı",
              userImage: postData['userImage'] ?? "https://via.placeholder.com/150",
              postImage: postImage,
              postDescription: postData['description'] ?? "",
              likes: postData['likes'] ?? 0,
              comments: postData['comments'] ?? 0,
              createdAt: postData['createdAt'] is Timestamp
                  ? postData['createdAt']
                  : Timestamp.now(),
              postRef: post.reference,
              imageCount: imageUrls.length, // 👈 yeni parametre
            );

          },
        );
      },
    );
  }


  /// **🔥 Kullanıcının Post Kartı (Silme + Düzenleme)**
  Widget _buildPostCard(BuildContext context, {
    required String postId,
    required String username,
    required String userImage,
    required String postImage,
    required String postDescription,
    required int likes,
    required int comments,
    required Timestamp createdAt,
    required DocumentReference postRef,
    required int imageCount, // 👈 bu eklendi

  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(
          currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final updatedImage = userData?['profileUrl'] ?? userImage;
        final updatedName = "${userData?['firstName'] ??
            ''} ${userData?['lastName'] ?? ''}".trim();
        final nameToShow = updatedName.isNotEmpty ? updatedName : username;

        return Card(
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(updatedImage),
                    radius: 20,
                  ),
                  title: Text(
                    nameToShow,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _formatTimestamp(createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.black),
                        onPressed: () => _editPost(context, postId, postDescription),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22),
                        onPressed: () => _deletePost(context, postRef),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          postImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                        if (imageCount > 1)
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
                                "📷 $imageCount",
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  child: Text(postDescription,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.heart, size: 16),
                      const SizedBox(width: 5),
                      Text("$likes"),
                      const SizedBox(width: 12),
                      const FaIcon(FontAwesomeIcons.comment, size: 16),
                      const SizedBox(width: 5),
                      Text("$comments"),
                    ],
                  ),
                ),

                // 👇 Yorumları buraya bas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child:_buildCommentList(postId, currentUser.uid),
                ),

              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildAdoptionCard(
      BuildContext context, {
        required String postId,
        required String animalType,
        required String ownerName,
        required String city,
        required String imageUrl,
        required String description,
        required DocumentReference postRef,
        required bool isAdopted,
      }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final updatedImage = userData?['profileUrl'] ?? "";
        final updatedName = "${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}".trim();
        final nameToShow = updatedName.isNotEmpty ? updatedName : ownerName;

        return Stack(
          children: [
            Card(
              elevation: 10,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: updatedImage.isNotEmpty
                          ? CircleAvatar(
                        backgroundImage: NetworkImage(updatedImage),
                        radius: 20,
                      )
                          : const CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 20,
                      ),
                      title: Text(
                        "$animalType - $city",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "İlan Sahibi: $nameToShow",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: isAdopted
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                        child: const Text(
                          "Sahiplendirildi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.black),
                            onPressed: () => _editAdoptionPost(context, postId, description),
                          ),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.paw,
                              color: Colors.green,
                              size: 22,
                            ),
                            tooltip: "Sahiplendirdim",
                            onPressed: () => _showAdoptionConfirmationDialog(
                              context,
                              postId,
                              animalType,
                              description,
                              postRef,
                              imageUrl,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 1, // 🔄 1:1 kare görünüm istersen
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        );

      },
    );
  }

  void _showAdoptionConfirmationDialog(
      BuildContext context,
      String postId,
      String animalType,
      String description,
      DocumentReference postRef,
      String imageUrl,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sahiplendirme Seçimi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Bu hayvan DoldurKabı aracılığıyla mı sahiplendirildi?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // DoldurKabı Üzerinden
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _selectReceiverFromMessages(
                    context,
                    postId,
                    animalType,
                    description,
                    postRef,
                    imageUrl,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.pets, color: Colors.purple),
                      SizedBox(width: 12),
                      Text(
                        "DoldurKabı Üzerinden",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // DoldurKabı Dışında
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context); // BottomSheet'i kapat

                  // ✅ Direkt Firestore'a kayıt yap
                  _saveAdoptionRecord(
                    context,
                    postId,
                    animalType,
                    null,
                    false,
                    imageUrl,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.home_outlined, color: Colors.teal),
                      SizedBox(width: 12),
                      Text(
                        "DoldurKabı Dışında",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),



              const SizedBox(height: 10),

              // İptal
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.cancel, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                        "İptal",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveAdoptionRecord(
      BuildContext context,
      String postId,
      String animalType,
      String? receiverEmail,
      bool isFromApp,
      String imageUrl,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔥 Firestore'a kayıt
      await FirebaseFirestore.instance.collection('adoptionRecords').add({
        'animalId': postId,
        'animalType': animalType,
        'giverUserId': user.email,
        'receiverUserId': receiverEmail,
        'isFromDoldurKabi': isFromApp,
        'date': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });

      // ✅ İlanın "sahiplendirildi" durumunu güncelle
      await FirebaseFirestore.instance
          .collection('adoption_posts')
          .doc(postId)
          .update({'isAdopted': true});

      // 🟣 Sayfayı yenile ve başarı mesajı göster
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Sahiplendirme başarıyla kaydedildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("🔥 Firestore kayıt hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Hata oluştu! Lütfen tekrar deneyin."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _editAdoptionPost(BuildContext context, String postId,
      String existingDescription) {
    TextEditingController _controller = TextEditingController(
        text: existingDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("İlanı Düzenle"),
          content: TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Yeni açıklamayı girin...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('adoption_posts')
                    .doc(postId)
                    .update({
                  'description': _controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("İlan güncellendi!")),
                );
              },
              child: const Text("Kaydet", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _selectReceiverFromMessages(BuildContext context, String postId, String animalType, String description, DocumentReference postRef, String imageUrl) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('users', arrayContains: currentUser.email)
        .get();

    List<String> receiverEmails = [];
    for (var doc in snapshot.docs) {
      List users = doc['users'];
      String otherUser = users.firstWhere((email) => email != currentUser.email);
      if (!receiverEmails.contains(otherUser)) {
        receiverEmails.add(otherUser);
      }
    }

    if (receiverEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sahiplendirme yapılacak kullanıcı bulunamadı.")),
      );
      return;
    }

    // Tüm kullanıcıları Firestore'dan çek
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> receivers = usersSnapshot.docs
        .where((doc) => receiverEmails.contains(doc['email']))
        .map((doc) => {
      'email': doc['email'],
      'name': "${doc['firstName']} ${doc['lastName']}",
      'imageUrl': doc['profileUrl'] ?? '',
    })
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kime sahiplendirdiniz?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...receivers.map((user) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // BottomSheet'i kapat

                      // 🔥 Direkt sahiplendirme işlemini yap
                      _saveAdoptionRecord(
                        context,
                        postId,
                        animalType,
                        user['email'],
                        true,
                        imageUrl,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: user['imageUrl'] != ''
                                ? NetworkImage(user['imageUrl'])
                                : null,
                            child: user['imageUrl'] == '' ? const Icon(Icons.person) : null,
                            radius: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            user['name'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.cancel, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                        "İptal",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editLostPetPost(BuildContext context, String postId,
      String existingDescription) {
    TextEditingController _controller = TextEditingController(
        text: existingDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Kayıp İlanı Düzenle"),
          content: TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Yeni açıklamayı girin...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('lost_pets').doc(
                    postId).update({
                  'description': _controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kayıp ilanı güncellendi!")),
                );
              },
              child: const Text("Kaydet", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _deleteLostPetPost(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Kayıp İlanını Sil"),
          content: const Text(
              "Bu kayıp ilanını silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                await postRef.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kayıp ilanı silindi")),
                );
              },
              child: const Text("Sil", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  /// **🔥 Postu Düzenleme Dialog'u**
  void _editPost(BuildContext context, String postId,
      String existingDescription) {
    TextEditingController _controller = TextEditingController(
        text: existingDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // ✅ Köşeleri yuvarlat
          ),
          title: Text(
            "Gönderiyi Düzenle",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700], // 🎨 Daha güzel bir başlık rengi
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Yeni açıklamayı girin...",
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  // 🟡 Hafif arkaplan rengi
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // ✨ Kenarları kaldır
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          // ✅ Butonları ortala
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300], // 🚫 Gri iptal butonu
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
              ),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .update({
                  'description': _controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gönderi güncellendi!",
                        style: GoogleFonts.poppins(fontSize: 14)),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700], // 🔥 Mor kaydet butonu
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
              ),
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  /// **🔥 Post Silme Fonksiyonu**
  void _deletePost(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // ✅ Köşeleri yuvarlat
          ),
          title: Text(
            "Gönderiyi Sil",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700], // 🔴 Kırmızı başlık (Daha dikkat çekici)
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded, // ⚠️ Uyarı ikonu
                color: Colors.red[700],
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "Bu gönderiyi silmek istediğinizden emin misiniz? \nBu işlem geri alınamaz!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          // ✅ Butonları ortala
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300], // 🚫 Gri iptal butonu
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
              ),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await postRef.delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gönderi silindi!",
                        style: GoogleFonts.poppins(fontSize: 14)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700], // 🔥 Kırmızı silme butonu
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
              ),
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  /// **🔥 Zaman Formatlama Fonksiyonu**
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmeyen zaman";

    DateTime postTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(postTime);

    if (difference.inMinutes < 1) {
      return "Az önce";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} dakika önce";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} saat önce";
    } else {
      return "${postTime.day}/${postTime.month}/${postTime.year}";
    }
  }

  Widget _buildCommentList(String postId, String postOwnerId) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // hiç yorum yoksa boş göster
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: snapshot.data!.docs.map((doc) {
            final commentData = doc.data() as Map<String, dynamic>;
            final commentId = doc.id;
            final commentText = commentData['text'] ?? '';
            final commentUserName = commentData['userName'] ?? 'Bilinmeyen';
            final commentUserImage = commentData['userImage'] ?? '';
            final commentUserEmail = commentData['userEmail'] ?? '';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: commentUserImage.isNotEmpty
                    ? NetworkImage(commentUserImage)
                    : null,
                child: commentUserImage.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(
                commentUserName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: Text(
                commentText,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: currentUser != null &&
                  (currentUser.email == commentUserEmail || currentUser.uid == postOwnerId)
                  ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: "Yorumu Sil",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Yorumu Sil"),
                      content: const Text("Bu yorumu silmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .collection('comments')
                                .doc(commentId)
                                .delete();

                            // Yorum sayısını 1 azalt
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .update({
                              'comments': FieldValue.increment(-1),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Yorum silindi.")),
                            );
                          },
                          child: const Text("Sil", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

}
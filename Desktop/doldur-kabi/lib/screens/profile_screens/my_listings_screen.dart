import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Yeni ikonlar için


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
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.white),
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
          _buildPostsTab(), // ✅ Kullanıcının gönderilerini gösteriyor
          _buildAdoptionsTab(), // ✅ Kullanıcının sahiplendirme ilanlarını gösterecek
          _buildLostPetsTab(), // ✅ Kayıp hayvan ilanlarını gösterecek!
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
          return Center(child: Text("Veri çekilirken hata oluştu: ${snapshot.error}"));
        }

        // 🔥 Eğer veri yoksa boş mesaj göster
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Henüz kayıp hayvan ilanınız bulunmamaktadır.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
              description: postData['location'] ?? "Konum Bilinmiyor",
              postRef: doc.reference,
              imageUrls: List<String>.from(postData['imageUrls'] ?? []), // 💥 EKLE BUNU
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
              title: Text(
                "$petName",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "📍 $city",
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
              child: firstImage.isNotEmpty
                  ? Image.network(
                firstImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              )
                  : Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[300],
                child: const Center(child: Text("Resim Yok")),
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
  }



  Widget _buildAdoptionsTab() {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Lütfen giriş yapın."));
    }

    Query query = _firestore.collection('adoption_posts')
        .where('ownerEmail', isEqualTo: currentUser.email) // 🔥 Kullanıcının ilanlarını alıyoruz
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        print("🔥 [DEBUG] Firestore bağlantısı çalışıyor...");

        if (snapshot.connectionState == ConnectionState.waiting) {
          print("⏳ [DEBUG] Firestore verisi yükleniyor...");
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("❌ [HATA] Firebase Hatası: ${snapshot.error}");
          return Center(child: Text("Veri çekilirken hata oluştu: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("📭 [DEBUG] Firestore'dan veri çekildi ama sonuç boş.");
          return Center(
            child: Text(
              "Henüz sahiplendirme ilanınız bulunmamaktadır.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        print("✅ [DEBUG] Firestore'dan ${snapshot.data!.docs.length} ilan çekildi.");

        var posts = snapshot.data!.docs;

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
        .where('userId', isEqualTo: currentUser.uid) // SADECE kullanıcının postları
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
          print("📭 [DEBUG] Hiç gönderi bulunamadı.");
          return const Center(
            child: Text(
              "Henüz gönderiniz bulunmamaktadır.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
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

            print("📌 [DEBUG] Post ID: ${post.id}, 📝 Açıklama: ${postData['description']}");

            return _buildPostCard(
              context,
              postId: post.id,
              username: postData['username'] ?? "Bilinmeyen Kullanıcı",
              userImage: postData['userImage'] ?? "https://via.placeholder.com/150",
              postImage: postData['imageUrl'] ?? "https://via.placeholder.com/300",
              postDescription: postData['description'] ?? "",
              likes: postData['likes'] ?? 0,
              comments: postData['comments'] ?? 0,
              createdAt: postData.containsKey('createdAt') && postData['createdAt'] is Timestamp
                  ? postData['createdAt']
                  : Timestamp.now(),
              postRef: post.reference,
            );
          },
        );
      },
    );
  }



  /// **🔥 Kullanıcının Post Kartı (Silme Özellikli)**
  /// **🔥 Kullanıcının Post Kartı (Silme + Düzenleme)**
  Widget _buildPostCard(
      BuildContext context, {
        required String postId,
        required String username,
        required String userImage,
        required String postImage,
        required String postDescription,
        required int likes,
        required int comments,
        required Timestamp createdAt,
        required DocumentReference postRef,
      }) {
    return Card(
      elevation: 10, // Gölgeyi biraz azalttım
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Kenarlardan boşluk ekledim
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Kartın içinde daha az boşluk bıraktım
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userImage),
                radius: 20, // Avatarı biraz küçülttüm
              ),
              title: Text(
                username,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, // Fontu küçülttüm
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                _formatTimestamp(createdAt),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.black), // 📝 Düzenleme Butonu
                    onPressed: () {
                      _editPost(context, postId, postDescription);
                    },
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22), // 🗑️ Silme Butonu
                    onPressed: () {
                      _deletePost(context, postRef);
                    },
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                postImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150, // **Yüksekliği küçülttüm**
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.purple,
                        strokeWidth: 5,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Resim yüklenemedi")),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                postDescription,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.heart, color: Colors.black), // ❤️ Beğeni Butonu
                      const SizedBox(width: 5),
                      Text("$likes"),
                      const SizedBox(width: 16),
                      const FaIcon(FontAwesomeIcons.comment, color: Colors.black), // 💬 Yorum Butonu
                      const SizedBox(width: 5),
                      Text("$comments"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    }) {
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
            leading: const FaIcon(FontAwesomeIcons.paw, color: Colors.deepPurple), // 🐾 Hayvan simgesi
            title: Text(
              "$animalType - $city",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              "İlan Sahibi: $ownerName",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.black), // 📝 Düzenleme Butonu
                  onPressed: () {
                    _editAdoptionPost(context, postId, description);
                  },
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22), // 🗑️ Silme Butonu
                  onPressed: () {
                    _deleteAdoptionPost(context, postRef);
                  },
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            )
                : Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Text("Resim Yok")),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
  );
}

void _editAdoptionPost(BuildContext context, String postId, String existingDescription) {
  TextEditingController _controller = TextEditingController(text: existingDescription);

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
              await FirebaseFirestore.instance.collection('adoption_posts').doc(postId).update({
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

void _deleteAdoptionPost(BuildContext context, DocumentReference postRef) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinizden emin misiniz?"),
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
                const SnackBar(content: Text("İlan silindi")),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

void _editLostPetPost(BuildContext context, String postId, String existingDescription) {
  TextEditingController _controller = TextEditingController(text: existingDescription);

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
              await FirebaseFirestore.instance.collection('lost_pets').doc(postId).update({
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
        content: const Text("Bu kayıp ilanını silmek istediğinizden emin misiniz?"),
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
void _editPost(BuildContext context, String postId, String existingDescription) {
  TextEditingController _controller = TextEditingController(text: existingDescription);

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
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100], // 🟡 Hafif arkaplan rengi
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // ✨ Kenarları kaldır
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center, // ✅ Butonları ortala
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300], // 🚫 Gri iptal butonu
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                'description': _controller.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Gönderi güncellendi!", style: GoogleFonts.poppins(fontSize: 14)),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700], // 🔥 Mor kaydet butonu
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center, // ✅ Butonları ortala
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300], // 🚫 Gri iptal butonu
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await postRef.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Gönderi silindi!", style: GoogleFonts.poppins(fontSize: 14)),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700], // 🔥 Kırmızı silme butonu
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
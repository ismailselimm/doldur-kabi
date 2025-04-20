import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_screens/login_screen.dart';
import 'comments_screen.dart';
import 'adopt_pet_screen.dart';
import 'lost_pets_screen.dart';
import 'create_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkUserLoginStatus();
    });
  }

  void _checkUserLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert();
    }
  }

  void _showLoginAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Topluluk Özellikleri",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[700]),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Topluluk sayfamızda gönderiler paylaşılmaktadır, hayvan sahiplendirme yapılmaktadır ve kayıp hayvan ilanı verilebilmektedir. "
                    "Bu özellikleri kullanabilmek için giriş yapmanız gerekmektedir.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF9346A1),
        /*  leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.trophy, color: Colors.white, size: 23),
            tooltip: 'Puan Tablosu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaderboardScreen()),
              );
            },
          ), */
          title: Text(
            'Topluluk',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          automaticallyImplyLeading: false, // 🔥 Geri butonunu tamamen kaldır!
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.volunteer_activism, color: Colors.white, size: 25,),
              tooltip: 'Sahiplen',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdoptionScreen()),
                );
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.white, size: 23), // Kayıp Hayvanlar
              tooltip: 'Kayıp Hayvanlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LostPetsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var posts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var post = posts[index];

                var postData = post.data() as Map<String, dynamic>;

                return _buildPostCard(
                  context,
                  postId: post.id,
                  username: postData['username'] ?? "Bilinmeyen Kullanıcı",
                  userImage: postData['userImage'] ?? "https://via.placeholder.com/150",
                  postImage: postData['imageUrl'] ?? "https://via.placeholder.com/300",
                  postDescription: postData['description'] ?? "",
                  likes: postData['likes'] ?? 0,
                  comments: postData['comments'] ?? 0,
                  likedBy: List<String>.from(postData['likedBy'] ?? []),
                  createdAt: postData.containsKey('createdAt') && postData['createdAt'] is Timestamp
                      ? postData['createdAt']
                      : Timestamp.now(), // 🔥 Burayı ekledik!
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF9346A1),
        child: const FaIcon(FontAwesomeIcons.edit, color: Colors.white, size: 23),
      onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
      ),
    );
  }


  Widget _buildPostCard(
      BuildContext context, {
        required String postId,
        required String username,
        required String userImage,
        required String postImage,
        required String postDescription,
        required int likes,
        required int comments,
        required List<String> likedBy,
        required Timestamp createdAt, // Zamanı ekledik!
      }) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isLiked = user != null && likedBy.contains(user.email);

    return Card(
      elevation: 10,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showPostOptions(context, postId),
            ),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userImage),
              radius: 24,
            ),
            title: Text(
              username,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              _formatTimestamp(createdAt), // Firestore'dan gelen zamanı formatlıyoruz
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                postImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purple, // 🎨 Mor renkli loading
                        strokeWidth: 5, // Daha kalın çember
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Resim yüklenemedi")),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              postDescription,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.black,
                        size: 28, // İkon boyutunu biraz büyüttüm, istersen değiştir
                      ),
                      onPressed: () {
                        if (user != null) {
                          _toggleLike(postId, user!.email!, isLiked);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Beğenmek için giriş yapmalısınız!")),
                          );
                        }
                      },
                    ),

                    Text(
                      '$likes',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.comment, color: Colors.black),
                      onPressed: () {
                        _showCommentsScreen(context, postId); // 🔥 Yorumları gösterme ekranına git
                      },
                    ),
                    Text(
                      '$comments',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.shareFromSquare, color: Colors.black),
                  onPressed: () {
                    _sharePost(postDescription, postImage);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

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
    } else if (difference.inDays < 7) {
      return "${difference.inDays} gün önce";
    } else {
      return "${postTime.day}/${postTime.month}/${postTime.year}";
    }
  }


  void _sharePost(String description, String imageUrl) {
    final String text = "$description\n\n📸 Resim: $imageUrl";

    print("✅ Paylaşım Butonuna Basıldı! Paylaşılan İçerik: \n$text"); // Debug için

    Share.share(text);
  }

  /// **🔥 Beğenme (Like) İşlevi**
  Future<void> _toggleLike(String postId, String userEmail, bool isLiked) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userEmail]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userEmail]),
      });
    }
  }

  void _showReportDialog(BuildContext context, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Gönderiyi Bildir"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text("Müstehcen içerik"),
                    value: "Müstehcen içerik",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Spam / Rahatsız edici"),
                    value: "Spam / Rahatsız edici",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Sahte içerik"),
                    value: "Sahte içerik",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                  RadioListTile<String>(
                    title: const Text("Diğer"),
                    value: "Diğer",
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                    Navigator.pop(ctx);

                    await FirebaseFirestore.instance.collection('complaints').add({
                      'type': 'Gönderi',
                      'contentId': postId,
                      'reportedBy': user.email,
                      'reason': selectedReason,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "Teşekkürler",
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        // Burayı güncelledik: görünür bir boş widget verdik
                        return const Material(
                          type: MaterialType.transparency,
                          child: SizedBox.expand(), // Ekranı kaplasın ve animasyon başlasın
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        final curvedValue = Curves.easeOutBack.transform(anim1.value);

                        return Opacity(
                          opacity: anim1.value,
                          child: Transform.scale(
                            scale: curvedValue,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 26),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        "Gönderiyi bildirdiğiniz için teşekkür ederiz 💚",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.none,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    // 2 saniye sonra otomatik kapansın
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).maybePop();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedReason != null ? Colors.purple : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Bildir"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPostOptions(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.redAccent),
                title: const Text("Bu gönderiyi bildir"),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context, postId);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// **🔥 Yorum Ekleme Dialog**
  void _showCommentsScreen(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: postId),
      ),
    );
  }
}

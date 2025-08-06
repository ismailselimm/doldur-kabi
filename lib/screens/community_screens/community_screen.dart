import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doldur_kabi/screens/admin_screens/reports_screen.dart';
import 'package:doldur_kabi/screens/community_screens/likers_screen.dart';
import 'package:doldur_kabi/screens/community_screens/user_profile_screen.dart';
import 'package:doldur_kabi/widgets/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/shimmer_avatar.dart';
import '../home_screens/main_home_page.dart';
import '../login_screens/login_screen.dart';
import 'comments_screen.dart';
import 'adopt_pet_screen.dart';
import 'lost_pets_screen.dart';
import 'create_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/painting.dart'; // NetworkImage boyutu için
import 'package:doldur_kabi/widgets/banner_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();

}

class _CommunityScreenState extends State<CommunityScreen> with AutomaticKeepAliveClientMixin {

  Map<String, Size> _imageSizes = {}; // 👈 her post için image boyutu cache’lenecek
  final ScrollController _scrollController = ScrollController();
  bool isAnimating = false; // state'e ekle


  @override
  bool get wantKeepAlive => true;
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
                "Topluluk sayfasında kullanıcılar gönderiler paylaşır, yorum yapar ve etkileşimde bulunur. Bu alanlara erişmek için giriş yapmanız gerekmektedir.",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
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
              const SizedBox(height: 8), // 🔥 Butonlar arasına boşluk
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  SelectedIndex.changeSelectedIndex(0);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()), // 🔥 Giriş yapmadan anasayfaya yönlendir
                  );
                },
                child: const Text(
                  "Giriş Yapmadan Devam Et",
                  style: TextStyle(fontSize: 16, color: Colors.purple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🔥 bunu unutma yoksa çalışmaz
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF9346A1),
          title: Text(
            'Topluluk',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0,
          leadingWidth: 130, // 🔧 BÜYÜTÜLDÜ
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 34, color: Colors.white),              tooltip: 'Yeni Özellik',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePostScreen()),
                );
              },

            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          key: const PageStorageKey('communityScrollKey'),
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('isApproved', isEqualTo: true) // 🔥 SADECE ONAYLANANLAR
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var posts = snapshot.data!.docs;
                List<Widget> postWidgets = [];

                for (int i = 0; i < posts.length; i++) {
                  if (i == 0) {
                    postWidgets.add(const SizedBox(height: 12));
                    postWidgets.add(const BannerWidget());
                    postWidgets.add(const SizedBox(height: 12));
                  }

                  var post = posts[i];
                  var postData = post.data() as Map<String, dynamic>;

                  postWidgets.add(_buildPostCard(
                    context,
                    postId: post.id,
                    postOwnerId: postData['userId'] ?? "",
                    imageUrls: List<String>.from(postData['imageUrls'] ?? []),
                    postImage: (postData['imageUrls'] != null && postData['imageUrls'].isNotEmpty)
                        ? postData['imageUrls'][0]
                        : "https://via.placeholder.com/300",
                    postDescription: postData['description'] ?? "",
                    likes: postData['likes'] ?? 0,
                    comments: postData['comments'] ?? 0,
                    likedBy: List<String>.from(postData['likedBy'] ?? []),
                    createdAt: postData['createdAt'] ?? Timestamp.now(),
                    cityDistrict: postData['cityDistrict'] ?? "",
                  ));


                  if ((i + 1) % 3 == 0 && (i + 1) < posts.length) {
                    postWidgets.add(const SizedBox(height: 12));
                    postWidgets.add(const BannerWidget());
                    postWidgets.add(const SizedBox(height: 12));
                  }
                }

                return Column(children: postWidgets);
              },
            )
          ],
        ),
      ),
    );
  }




  Widget _buildPostCard(
      BuildContext context, {
        required String postId,
        required String postOwnerId,
        required String postImage,
        required String postDescription,
        required int likes,
        required int comments,
        required List<String> likedBy,
        required Timestamp createdAt,
        required String? cityDistrict,
        required List<String> imageUrls,
      }) {

    final User? user = FirebaseAuth.instance.currentUser;
    final bool isLiked = user != null && likedBy.contains(user.email);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(postOwnerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(); // veya loading widget
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userImage = userData['profileUrl'] ?? 'https://via.placeholder.com/150';
        final username = "${userData['firstName']} ${userData['lastName']}";
        final postOwnerEmail = (userData.containsKey('email') && userData['email'] != null && userData['email'].toString().isNotEmpty)
            ? userData['email']
            : 'bos@email.com';


        return Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _showPostOptions(
                    context,
                    postId,
                    postOwnerId,
                    postDescription,
                    postOwnerEmail,
                  ),
                ),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: postOwnerId,
                          userEmail: postOwnerEmail,
                        ),
                      ),
                    );
                  },
                  child: ShimmerAvatar(
                    imageUrl: userImage.isNotEmpty
                        ? userImage
                        : 'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                    radius: 24,
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: postOwnerId,
                          userEmail: postOwnerEmail,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTimestamp(createdAt),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // 🔥 Görsel + Konum etiketi
              FutureBuilder<Size>(
                future: _getImageSize(postImage),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  final size = snapshot.data!;
                  final aspectRatio = size.width / size.height;
                  final PageController controller = PageController();
                  int currentIndex = 0;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Stack(
                        children: [
                          ClipRRect(
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: PageView.builder(
                                controller: controller,
                                itemCount: imageUrls.length,
                                onPageChanged: (index) => setState(() => currentIndex = index),
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: imageUrls[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          color: Colors.grey[300],
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(child: Icon(Icons.broken_image)),
                                      ),
                                    );
                                  }
                              ),
                            ),
                          ),

                          // 🔘 Konum etiketi
                          if (cityDistrict != null && cityDistrict.trim().isNotEmpty)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "📍 $cityDistrict",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                          // 🔢 Foto index göstergesi
                          if (imageUrls.length > 1)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${currentIndex + 1}/${imageUrls.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),

              // 🔥 Açıklama + Beğeni Satırı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(postDescription,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), // üst padding sıfır
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🧱 Beğeni - Yorum - Paylaş Satırı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [

                            // ❤️ Beğeni (ikon + sayı)
                            GestureDetector(
                              onTap: () {
                                if (user != null) {
                                  setState(() => isAnimating = true); // animasyonu başlat
                                  _toggleLike(postId, user.email!, isLiked);
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    if (mounted) setState(() => isAnimating = false); // animasyonu sıfırla
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Beğenmek için giriş yapmalısınız!")),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 200),
                                    scale: isAnimating ? 1.4 : 1.0,
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 26,
                                      color: isLiked ? Colors.red : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${likedBy.length}",
                                    style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 💬 Yorum (ikon + sayı)
                            GestureDetector(
                              onTap: () => _showCommentsScreen(context, postId),
                              child: Row(
                                children: [
                                  const Icon(FontAwesomeIcons.comment, size: 24, color: Colors.black),
                                  const SizedBox(width: 4),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('comments')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      final commentCount = snapshot.data?.docs.length ?? 0;
                                      return Text(
                                        "$commentCount",
                                        style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black),
                                      );
                                    },
                                  )

                                ],
                              ),
                            ),
                          ],
                        ),

                        // 🔁 Paylaş butonu en sağda
                        IconButton(
                          icon: const Icon(FontAwesomeIcons.paperPlane, size: 20, color: Colors.black),
                          onPressed: () {
                            final shareLink = 'https://doldurkabi.com/post/$postId';
                            final shareText = '''
👥 Yeni bir topluluk gönderisine göz at!

📌 Açıklama: $postDescription

🔗 Gönderiyi incele: $shareLink
''';

                            Share.share(shareText);
                          },
                        ),

                      ],
                    ),

                    const SizedBox(height: 8),

                    // ❤️ Beğenenlerin profil fotoları
                    if (likedBy.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LikersScreen(likedBy: likedBy),
                            ),
                          );
                        },
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('email', whereIn: likedBy.take(3).toList())
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final docs = snapshot.data!.docs;
                            final extraCount = likedBy.length - docs.length;

                            return Row(
                              children: [
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: (docs.length * 24).toDouble(),
                                  height: 32,
                                  child: Stack(
                                    children: List.generate(docs.length, (index) {
                                      final data = docs[index].data() as Map<String, dynamic>;
                                      final profileUrl = data['profileUrl'] ??
                                          "https://cdn-icons-png.flaticon.com/512/847/847969.png";

                                      return Positioned(
                                        left: index * 18.0,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundImage: NetworkImage(profileUrl),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  extraCount > 0 ? "+$extraCount kişi daha beğendi" : "beğendi",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),


                  ],
                ),
              ),




              const SizedBox(height: 16),
            ],


          ),
        );
      },
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

  Future<Size> _getImageSize(String imageUrl) async {
    if (_imageSizes.containsKey(imageUrl)) return _imageSizes[imageUrl]!;

    final Completer<Size> completer = Completer();
    final ImageStream imageStream = NetworkImage(imageUrl).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
      _imageSizes[imageUrl] = size;
      completer.complete(size);
    });
    imageStream.addListener(listener);
    return completer.future;
  }

  void _showPostOptions(BuildContext context, String postId, String postOwnerId, String postDescription, String postOwnerEmail) {
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
                onTap: () async {
                  Navigator.pop(context); // alt sheet'i kapat
                  await showReportDialog(
                    context,
                    targetId: postId,
                    targetTitle: postDescription,
                    targetType: "Topluluk Gönderisi",
                    targetUserEmail: postOwnerEmail,
                  );
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

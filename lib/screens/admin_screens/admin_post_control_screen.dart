import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPostControlScreen extends StatelessWidget {
  const AdminPostControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postsRef = FirebaseFirestore.instance.collection('posts');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gönderi Kontrol",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: postsRef
            .where('isApproved', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Hiç gönderi bulunamadı."));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>;

              final cityDistrict = data['cityDistrict'] ?? '';
              final parts = cityDistrict.split(' - ');
              final city = parts.isNotEmpty ? parts[0] : '';
              final district = parts.length > 1 ? parts[1] : '';

              return _buildAdminPostCard(
                context,
                username: data['username'] ?? 'Bilinmeyen',
                userImage: data['userImage'] ?? '',
                imageUrls: data['imageUrls'] ?? [],
                description: data['description'] ?? '',
                likes: data['likedBy'] != null ? (data['likedBy'] as List).length : 0,
                comments: data['comments'] ?? 0,
                createdAt: data['createdAt'],
                postRef: post.reference,
                city: city,
                district: district,
              );


            },
          );
        },
      ),
    );
  }

  Widget _buildAdminPostCard(
      BuildContext context, {
        required String username,
        required String userImage,
        required List<dynamic> imageUrls,
        required String description,
        required int likes,
        required int comments,
        required Timestamp createdAt,
        required DocumentReference postRef,
        required String city,
        required String district,
      }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userImage),
                radius: 22,
              ),
              title: Text(username, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _formatTimestamp(createdAt),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.green, size: 22),
                    onPressed: () => _approvePost(context, postRef),
                    tooltip: "Onayla",
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22),
                    onPressed: () => _deletePost(context, postRef),
                    tooltip: "Sil",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (imageUrls.length > 1)
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Center(child: Text("Görsel yüklenemedi")),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${imageUrls.length} Fotoğraf",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrls.isNotEmpty ? imageUrls[0] : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Görsel yüklenemedi")),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: Text(
                "$city - $district",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            Text(
              description,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.heart, size: 16),
                const SizedBox(width: 4),
                Text("$likes"),
                const SizedBox(width: 16),
                const FaIcon(FontAwesomeIcons.comment, size: 16),
                const SizedBox(width: 4),
                Text("$comments"),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _approvePost(BuildContext parentContext, DocumentReference postRef) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Gönderiyi Onayla"),
        content: const Text("Bu gönderiyi onaylamak istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // 👈 BURADA DEĞİŞTİ
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await postRef.update({'isApproved': true});
                Navigator.pop(dialogContext); // 👈 BURADA DA DEĞİŞTİ
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text("Gönderi onaylandı")),
                );
              } catch (e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text("Hata: $e")),
                );
              }
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }



  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmeyen zaman";
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Az önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${date.day}/${date.month}/${date.year}";
  }

  void _deletePost(BuildContext parentContext, DocumentReference postRef) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Gönderiyi Sil"),
        content: const Text("Bu gönderiyi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // 👈 Doğru context
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await postRef.delete();
                Navigator.pop(dialogContext); // 👈 Burayı da düzelt
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text("Gönderi silindi")),
                );
              } catch (e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text("Hata: $e")),
                );
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

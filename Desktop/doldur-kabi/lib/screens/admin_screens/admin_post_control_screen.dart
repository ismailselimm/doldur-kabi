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
        stream: postsRef.orderBy('createdAt', descending: true).snapshots(),
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

              return _buildAdminPostCard(
                context,
                username: data['username'] ?? 'Bilinmeyen',
                userImage: data['userImage'] ?? '',
                postImage: data['imageUrl'] ?? '',
                description: data['description'] ?? '',
                likes: data['likedBy'] != null ? (data['likedBy'] as List).length : 0,
                comments: data['comments'] ?? 0,
                createdAt: data['createdAt'],
                postRef: post.reference,
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
        required String postImage,
        required String description,
        required int likes,
        required int comments,
        required Timestamp createdAt,
        required DocumentReference postRef,
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
              trailing: IconButton(
                icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red, size: 22),
                onPressed: () => _deletePost(context, postRef),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                postImage,
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
            const SizedBox(height: 10),
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmeyen zaman";
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Az önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${date.day}/${date.month}/${date.year}";
  }

  void _deletePost(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Gönderiyi Sil"),
        content: const Text("Bu gönderiyi silmek istediğinize emin misiniz?"),
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
                const SnackBar(content: Text("Gönderi silindi")),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

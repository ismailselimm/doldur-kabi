import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminComplaintsScreen extends StatelessWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirilenler',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            )),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final complaints = snapshot.data!.docs;

          if (complaints.isEmpty) {
            return Center(
              child: Text("Hiç şikayet bulunamadı.",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              final data = doc.data() as Map<String, dynamic>;
              final String targetType = data['targetType'] ?? '';
              final String collection = _getCollectionName(targetType);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(collection)
                    .doc(data['targetId'])
                    .get(),
                builder: (context, snapshot) {
                  final targetData = snapshot.data?.data() as Map<String, dynamic>?;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(); // bekleme süresi için boş kutu
                  }


                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🔷 $targetType",
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                        const SizedBox(height: 10),
                        if (targetType == 'Kullanıcı' && targetData != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  targetData['profileUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                                ),
                                radius: 28,
                                backgroundColor: Colors.deepPurple.shade100,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${targetData['firstName']} ${targetData['lastName']}",
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  if (targetData['email'] != null)
                                    Text(
                                      targetData['email'],
                                      style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black54),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("💬 Açıklama: Bu kullanıcı hakkında bir şikayet bildirildi.",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          if ((data['description'] ?? '').toString().isNotEmpty)
                            Text("📌 Açıklama: ${data['description']}", style: GoogleFonts.poppins()),
                        ],

                        Text("🎯 Hedef: ${data['targetTitle'] ?? '---'}", style: GoogleFonts.poppins()),
                        Text("📨 Şikayet Eden: ${data['reporterEmail'] ?? '---'}", style: GoogleFonts.poppins()),
                        Text("👤 Hedef Kullanıcı: ${data['targetUserEmail'] ?? '---'}", style: GoogleFonts.poppins()),
                        Text("📂 Sebep: ${data['reason'] ?? '---'}", style: GoogleFonts.poppins()),
                        if ((data['description'] ?? '').toString().trim().isNotEmpty)
                          Text("📌 Açıklama: ${data['description']}", style: GoogleFonts.poppins()),
                        const Divider(height: 28, color: Colors.grey),

                        if (targetData != null) ...[
                          Text("🔍 Şikayet Edilen İçerik:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          if ((targetData['imageUrls'] ?? []).isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                targetData['imageUrls'][0],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if ((targetData['imageUrl'] ?? '').toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                targetData['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),


                          // 👇 Eğer 'lastFilledImageUrl' varsa onu göster (Mama Kabı için)
                          if ((targetData?['lastFilledImageUrl'] ?? '').toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                targetData!['lastFilledImageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                          const SizedBox(height: 10),
                          if (targetData.containsKey("petName"))
                            Text("🌺 Adı: ${targetData['petName'] ?? '---'}", style: GoogleFonts.poppins()),
                          if (targetData.containsKey("location"))
                            Text("📍 Konum: ${targetData['location'] ?? '---'}", style: GoogleFonts.poppins()),
                          if ((targetData['description'] ?? '').toString().trim().isNotEmpty)
                            Text("💬 Açıklama: ${targetData['description']}", style: GoogleFonts.poppins()),
                        ],

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final sure = await _confirm(context, "İçeriği ve şikayeti silmek istediğine emin misin?");
                                  if (!sure) return;

                                  try {
                                    if (data['targetType'] == 'Yorum') {
                                      final relatedPostId = data['relatedPostId'];
                                      final commentId = data['targetId'];

                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(relatedPostId)
                                          .collection('comments')
                                          .doc(commentId)
                                          .delete();
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection(collection)
                                          .doc(data['targetId'])
                                          .delete();
                                    }


                                    await doc.reference.delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("İçerik ve şikayet silindi ✅"),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Hata oluştu: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete_forever, size: 18),
                                label: const Text("İçeriği Sil"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final sure = await _confirm(context, "Şikayeti silmek istiyor musun?");
                                  if (sure) await doc.reference.delete();
                                },
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text("Şikayeti Sil"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatTimestamp(data['createdAt']),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getCollectionName(String type) {
    switch (type) {
      case 'Kayıp Hayvan İlanı':
        return 'lost_pets';
      case 'Sahiplendirme İlanı':
      case 'Sahiplendirme':
        return 'adoption_posts';
      case 'Topluluk Gönderisi':
      case 'Gönderi':
        return 'posts';
      case 'Hayvan Evi':
        return 'animalHouses';
      case 'Mama Kabı':
        return 'feedPoints';
      case 'Yorum':
        return 'posts'; // Yorumlar post alt koleksiyonu
      case 'Kullanıcı':
        return 'users'; // ✅ Bunu ekle yoksa boş döner ve crash olur
      default:
        return '';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'Tarih yok';
    final dt = timestamp.toDate();
    return "${dt.day}.${dt.month}.${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<bool> _confirm(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Evet")),
        ],
      ),
    ) ?? false;
  }
}

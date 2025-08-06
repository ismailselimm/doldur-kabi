import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminEmergencyReportsScreen extends StatelessWidget {
  const AdminEmergencyReportsScreen({super.key});

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint("❌ Kullanıcı bilgisi alınamadı: $e");
      return null;
    }
  }

  Future<void> _deleteReport(BuildContext context, String docId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu acil durum bildirimini silmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('emergency_reports').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bildirim silindi.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Acil Durum Bildirimleri',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Hiç acil durum bildirimi yok."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final reportDoc = docs[index];
              final data = reportDoc.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserInfo(userId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['reason'] ?? 'Sebep Yok',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text("Açıklama: ${data['description'] ?? 'Yok'}",
                              style: GoogleFonts.poppins()),
                          Text("Konum: ${data['address'] ?? 'Bilinmiyor'}",
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                          Text(
                            "Tarih: ${DateTime.fromMillisecondsSinceEpoch(data['timestamp'].millisecondsSinceEpoch).toLocal().toString().substring(0, 16)}",
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const Divider(height: 20),
                          if (userData != null) ...[
                            Text("📌 Bildiren:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text("📧 ${userData['email'] ?? ''}", style: GoogleFonts.poppins(fontSize: 13)),
                            Text("📱 ${userData['phone'] ?? ''}", style: GoogleFonts.poppins(fontSize: 13)),
                            Text("👤 ${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}",
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ],
                          if (data['images'] != null && data['images'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                height: 160,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: data['images'].length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, i) {
                                    final imageUrl = data['images'][i];
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(16),
                                            child: InteractiveViewer(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(imageUrl),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          height: 160,
                                          fit: BoxFit.contain, // 👈 Kırpmasın, tam oranla küçültsün
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),


                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              onPressed: () => _deleteReport(context, reportDoc.id),
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                            ),
                          )
                        ],
                      ),
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminVetApplicationsScreen extends StatelessWidget {
  const AdminVetApplicationsScreen({super.key});

  Future<void> _approveApplication(String docId) async {
    await FirebaseFirestore.instance
        .collection('vetApplications')
        .doc(docId)
        .update({'status': 'approved'});
  }

  Future<void> _deleteApplication(String docId) async {
    await FirebaseFirestore.instance
        .collection('vetApplications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3FB),
      appBar: AppBar(
        title: Text(
          'Veteriner Onay',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vetApplications')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Bekleyen başvuru yok.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final name = data['businessName'] ?? 'Veteriner';
              final address = data['address'] ?? 'Adres yok';
              final phone = data['phone'] ?? 'Telefon yok';
              final isVolunteer = data['isVolunteer'] == true;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(address,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(phone, style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                      if (isVolunteer)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Gönüllü başvuru",
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.deepPurple),
                          ),
                        ),
                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Başvuru: ${_formatDate(createdAt)}",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.green),
                            onPressed: () async {
                              final onay = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  title: const Text("Onayla"),
                                  content: const Text("Bu veteriner başvurusunu onaylamak istediğinize emin misiniz?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("İptal"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Onayla", style: TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                ),
                              );

                              if (onay == true) {
                                await _approveApplication(docId);

                                // Başarı mesajı
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: const [
                                        Icon(Icons.verified, color: Colors.green),
                                        SizedBox(width: 10),
                                        Text("Başvuru Onaylandı"),
                                      ],
                                    ),
                                    content: const Text("Veteriner başvurusu başarıyla onaylandı."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Tamam"),
                                      )
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                            onPressed: () async {
                              final onay = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  title: const Text("Başvuru Sil"),
                                  content: const Text("Bu başvuruyu silmek istiyor musun?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("İptal"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Sil", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (onay == true) {
                                await _deleteApplication(docId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Başvuru silindi.")),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

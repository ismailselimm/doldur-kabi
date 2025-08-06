import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<int> _getAdoptedCount(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('adoption_posts')
        .where('ownerId', isEqualTo: userId)
        .where('isAdopted', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getReceivedCount(String userEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('adoptionRecords')
        .where('receiverUserId', isEqualTo: userEmail) // 👈 UID değil, email!
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcılar', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userEmail = data['email'] ?? '';
              final userId = docs[index].id; // 👈 Bunu ekle geri


              final adSoyad = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '-';
              final birth = data['birthYear'] ?? '-';
              final tc = data['tc'] ?? '-';
              final kurum = data['institution'] ?? '-';
              final profilUrl = data['profileUrl'] ?? '';
              final tarih = (data['createdAt'] as Timestamp?)?.toDate();
              final mama = data['mamaDoldurmaSayisi'] ?? 0;
              final ev = data['hayvanEviSayisi'] ?? 0;
              final nokta = data['beslemeNoktasiSayisi'] ?? 0;
              final gonderi = data['gonderiSayisi'] ?? 0;

              return FutureBuilder<List<int>>(
                future: Future.wait([
                  _getAdoptedCount(userId),       // ✅ UID’ye göre çekiyoruz
                  _getReceivedCount(userEmail),   // ✅ email’e göre çekiyoruz
                ]),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sahiplendirdi = snap.data?[0] ?? 0;
                  final sahiplenilen = snap.data?[1] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: profilUrl.isNotEmpty
                                ? NetworkImage(profilUrl)
                                : const AssetImage('assets/images/default_user.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(adSoyad, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text("📞 $phone", style: GoogleFonts.poppins(fontSize: 13)),
                                Text("🎂 $birth", style: GoogleFonts.poppins(fontSize: 13)),
                                Text("🏫 $kurum", style: GoogleFonts.poppins(fontSize: 13)),
                                Text("🆔 TC: $tc", style: GoogleFonts.poppins(fontSize: 13)),
                                if (tarih != null)
                                  Text(
                                    "🗓 Kayıt: ${tarih.day}.${tarih.month}.${tarih.year} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    _stat(Icons.fastfood, mama),
                                    _stat(Icons.home, ev),
                                    _stat(Icons.location_pin, nokta),
                                    _stat(Icons.send, gonderi),
                                    _stat(Icons.pets, sahiplendirdi, label: "Sahiplendirdi"),
                                    _stat(Icons.favorite, sahiplenilen, label: "Sahiplendi"),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  Widget _stat(IconData icon, int value, {String? label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label != null ? "$label: $value" : value.toString(), style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }
}

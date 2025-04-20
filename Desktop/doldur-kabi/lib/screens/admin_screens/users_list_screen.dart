import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kullanıcılar',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final adSoyad = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
              final email = data['email'] ?? '';
              final profilUrl = data['profileUrl'] ?? '';
              final tarih = (data['createdAt'] as Timestamp?)?.toDate();
              final mama = data['mamaDoldurmaSayisi'] ?? 0;
              final ev = data['hayvanEviSayisi'] ?? 0;
              final nokta = data['beslemeNoktasiSayisi'] ?? 0;
              final gonderi = data['gonderiSayisi'] ?? 0;
              final puan = data['points'] ?? 0;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: profilUrl.isNotEmpty
                            ? NetworkImage(profilUrl)
                            : const AssetImage('assets/images/default_user.png') as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adSoyad,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            Text(email,
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                            if (tarih != null)
                              Text(
                                "Kayıt: ${tarih.day}.${tarih.month}.${tarih.year} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                _buildStat(Icons.fastfood, mama),
                                _buildStat(Icons.home, ev),
                                _buildStat(Icons.location_pin, nokta),
                                _buildStat(Icons.send, gonderi),
                                _buildStat(Icons.star, puan),
                              ],
                            )
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
      ),
    );
  }

  Widget _buildStat(IconData icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 4),
        Text(value.toString(), style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }
}

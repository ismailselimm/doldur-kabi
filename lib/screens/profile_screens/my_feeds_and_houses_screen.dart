import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home_screens/main_home_page.dart';

class MyFeedsAndHousesScreen extends StatefulWidget {
  const MyFeedsAndHousesScreen({super.key});

  @override
  State<MyFeedsAndHousesScreen> createState() => _MyFeedsAndHousesScreenState();
}

class _MyFeedsAndHousesScreenState extends State<MyFeedsAndHousesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _delete(String collection, String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();

    if (!mounted) return; // 🛡️ Widget hâlâ aktif mi kontrol et
    setState(() {});      // 🔄 Yeniden çiz
  }

  Widget _buildCard(Map<String, dynamic> data, String docId, String collection) {
    String imagePath;

    if (collection == 'animalHouses') {
      imagePath = 'assets/images/pethouse.png';
    } else {
      imagePath = data['animal'] == 'dog'
          ? 'assets/images/dogfood.png'
          : 'assets/images/catfood.png';
    }

    final imageUrl = data['imageUrl'] ?? data['lastFilledImageUrl'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.asset(imagePath, width: 30, height: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['address'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tarih: ${(data['date'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? 'Yok'}",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFFFDF6F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "Emin misiniz?",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        "Bu işlemi geri alamazsınız. Devam etmek istiyor musunuz?",
                        style: GoogleFonts.poppins(fontSize: 15.5, color: Colors.grey[800]),
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Vazgeç"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _delete(collection, docId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          label: const Text("Evet, Sil"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 📷 Görsel (sadece tekli)
          if (imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(context, imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 140,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),


        ],
      ),
    );
  }

  Widget _buildList(String collection) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection(collection)
          .where('addedBy', isEqualTo: user?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Henüz DoldurKabı'na katkıda bulunmadınız.",
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  SelectedIndex.changeSelectedIndex(0);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9346A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Katkı Yapmaya Başla!", style: GoogleFonts.poppins(fontSize: 15.5)),
              ),
            ],
          );
        }

        final docs = snapshot.data!.docs;

        docs.sort((a, b) {
          final aDate = (a['date'] as Timestamp?)?.toDate();
          final bDate = (b['date'] as Timestamp?)?.toDate();
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return ListView.builder(
          itemCount: docs.length + (collection == 'feedPoints' ? 1 : 0), // 🔥 Ek kutu varsa +1
          itemBuilder: (context, index) {
            if (collection == 'feedPoints' && index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF9346A1)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.pets, color: Color(0xFF9346A1), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "DoldurKabı sayesinde daha önce eklediğiniz mama kabının en son halini buradan takip edebilirsiniz.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = docs[collection == 'feedPoints' ? index - 1 : index].data() as Map<String, dynamic>;
            final docId = docs[collection == 'feedPoints' ? index - 1 : index].id;
            return _buildCard(data, docId, collection);
          },
        );
      },
    );
  }


  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF9346A1),
          centerTitle: true,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.white), // ← BACK ICON WHITE
          title: Text(
            'Katkılarım',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Mama Kapları"),
              Tab(text: "Hayvan Evleri"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildList('feedPoints'),
            _buildList('animalHouses'),
          ],
        ),
      ),
    );
  }
}

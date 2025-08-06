import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminAdControlScreen extends StatefulWidget {
  const AdminAdControlScreen({Key? key}) : super(key: key);

  @override
  State<AdminAdControlScreen> createState() => _AdminAdControlScreenState();
}

class _AdminAdControlScreenState extends State<AdminAdControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "İlan Kontrol",
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Sahiplendirme"),
            Tab(text: "Kayıp İlanları"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdoptionTab(),
          _buildLostPetsTab(),
        ],
      ),
    );
  }

  Widget _buildAdoptionTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoption_posts')
          .where('isApproved', isEqualTo: false) // 🔥 sadece onaylanmamışlar
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) return const Center(child: Text("Hiç sahiplendirme ilanı yok."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            return _buildAdoptionCard(
              context,
              postRef: posts[index].reference,
              animalType: data['animalType'] ?? '',
              city: data['city'] ?? '',
              description: data['description'] ?? '',
              ownerName: data['ownerName'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _buildLostPetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_pets')
          .where('isApproved', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) return const Center(child: Text("Hiç kayıp ilanı yok."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            final imageList = data['imageUrls'] as List<dynamic>?;

            return _buildLostPetCard(
              context,
              postRef: posts[index].reference,
              petType: data['petType'] ?? '',
              petName: data['petName'] ?? '',
              city: data['city'] ?? '',
              location: data['location'] ?? '',
              imageUrls: List<String>.from(data['imageUrls'] ?? []),
              description: data['description'] ?? '',
            );

          },
        );
      },
    );
  }

  Widget _buildAdoptionCard(
      BuildContext context, {
        required DocumentReference postRef,
        required String animalType,
        required String city,
        required String description,
        required String ownerName,
        required String imageUrl,
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
              leading: const FaIcon(FontAwesomeIcons.paw, color: Colors.deepPurple),
              title: Text("$animalType - $city", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text("İlan Sahibi: $ownerName", style: GoogleFonts.poppins(fontSize: 12)),
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
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
            Text(description, style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Onayla"),
                  onPressed: () => _showApproveDialog(context, postRef),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: const Text("Sil"),
                  onPressed: () => _showDeleteDialog(context, postRef),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("İlanı Onayla"),
        content: const Text("Bu ilanı onaylamak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx); // önce dialogu kapat
              _approvePost(context, postRef); // sonra işlem yap
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePost(BuildContext context, DocumentReference postRef) async {
    try {
      await postRef.update({'isApproved': true});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ İlan başarıyla onaylandı"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildLostPetCard(
      BuildContext context, {
        required DocumentReference postRef,
        required String petType,
        required String petName,
        required String city,
        required String location,
        required List<dynamic> imageUrls,
        required String description,
      }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$city - $location",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 📸 Görsel ve sayfa göstergesi
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrls.isNotEmpty
                      ? SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Text("Görsel yüklenemedi")),
                          ),
                        );
                      },
                    ),
                  )
                      : Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("Görsel yok")),
                  ),
                ),

                // 📷 Resim sayısı göstergesi
                if (imageUrls.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${imageUrls.length} fotoğraf',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  description,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Onayla", style: TextStyle(color: Colors.white)),
                  onPressed: () => _showApproveDialog(context, postRef),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: const Text("Sil", style: TextStyle(color: Colors.white)),
                  onPressed: () => _showDeleteDialog(context, postRef),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




  void _showDeleteDialog(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deletePost(context, postRef);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, DocumentReference postRef) async {
    await postRef.delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İlan silindi"), backgroundColor: Colors.red));
    }
  }
}

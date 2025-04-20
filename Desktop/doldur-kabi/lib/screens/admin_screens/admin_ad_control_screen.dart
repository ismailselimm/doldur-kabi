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
            return _buildLostPetCard(
              context,
              postRef: posts[index].reference,
              petType: data['petType'] ?? '',
              petName: data['petName'] ?? '',
              city: data['city'] ?? '',
              location: data['location'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
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
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePost(context, postRef),
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLostPetCard(
      BuildContext context, {
        required DocumentReference postRef,
        required String petType,
        required String petName,
        required String city,
        required String location,
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
              leading: const Icon(Icons.location_pin, color: Colors.redAccent),
              title: Text(petName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text("$city - $location", style: GoogleFonts.poppins(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePost(context, postRef),
              ),
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
          ],
        ),
      ),
    );
  }

  void _deletePost(BuildContext context, DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("İlanı Sil"),
        content: const Text("Bu ilanı silmek istediğinize emin misiniz?"),
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
                const SnackBar(content: Text("İlan silindi")),
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

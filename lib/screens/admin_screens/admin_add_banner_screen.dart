import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddBannerScreen extends StatefulWidget {
  const AdminAddBannerScreen({super.key});

  @override
  State<AdminAddBannerScreen> createState() => _AdminAddBannerScreenState();
}

class _AdminAddBannerScreenState extends State<AdminAddBannerScreen> {
  File? _selectedImage;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isUploading = false;
  String? _selectedDocId;
  bool _isEditMode = false;


  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadBanner() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Firma adı zorunludur.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.png';
        final ref = FirebaseStorage.instance.ref().child('banners/$fileName');
        final bytes = await _selectedImage!.readAsBytes();
        await ref.putData(bytes);
        imageUrl = await ref.getDownloadURL();
      }

      String url = _urlController.text.trim();
      if (url.isNotEmpty && !url.startsWith("http")) {
        url = "https://$url";
      }

      if (_isEditMode && _selectedDocId != null) {
        final ref = FirebaseFirestore.instance.collection('banners').doc(_selectedDocId);
        final currentData = (await ref.get()).data();

        await ref.update({
          'name': _nameController.text.trim(),
          'url': url,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Banner güncellendi.")));
      } else {
        final query = await FirebaseFirestore.instance
            .collection('banners')
            .orderBy('order', descending: true)
            .limit(1)
            .get();

        final newOrder = query.docs.isEmpty
            ? 1
            : ((query.docs.first.data()['order'] ?? 0) as int) + 1;

        await FirebaseFirestore.instance.collection('banners').add({
          'imageUrl': imageUrl!,
          'order': newOrder,
          'name': _nameController.text.trim(),
          if (url.isNotEmpty) 'url': url,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Banner eklendi.")));
      }

      _nameController.clear();
      _urlController.clear();
      _selectedImage = null;
      _isEditMode = false;
      _selectedDocId = null;
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _swapOrders(
      String firstDocId, int firstOrder,
      String secondDocId, int secondOrder) async {
    print('Swapping $firstDocId($firstOrder) <--> $secondDocId($secondOrder)');

    final batch = FirebaseFirestore.instance.batch();
    final firstRef = FirebaseFirestore.instance.collection('banners').doc(firstDocId);
    final secondRef = FirebaseFirestore.instance.collection('banners').doc(secondDocId);

    batch.update(firstRef, {'order': secondOrder});
    batch.update(secondRef, {'order': firstOrder});

    await batch.commit();
  }

  Future<void> _deleteBanner(String docId) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Banner Sil"),
        content: const Text("Bu bannerı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil")),
        ],
      ),
    );

    if (confirm == true) {
      final collection = FirebaseFirestore.instance.collection('banners');
      await collection.doc(docId).delete();

      // 🔁 Kalan banner'ların order'ını güncelle
      final snapshot = await collection.orderBy('order').get();
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        batch.update(doc.reference, {'order': i + 1});
      }

      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Banner Ekle / Yönet',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : const Center(child: Text("Görsel Seç")),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Firma Adı",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: "Website Linki (opsiyonel)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadBanner,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text("Kaydet", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9346A1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text("Yüklü Bannerlar", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('banners')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text("Henüz banner eklenmedi."),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final currentOrder = data['order'] ?? 0;
                    final sponsorName = data['name'] ?? 'İsimsiz';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['imageUrl'],
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sponsorName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Sıra: $currentOrder",
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
                            ),
                            if (data['url'] != null)
                              Text(
                                data['url'],
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.teal),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: index > 0
                                      ? () async {
                                    final prev = docs[index - 1];
                                    final prevData = prev.data() as Map<String, dynamic>;
                                    await _swapOrders(doc.id, currentOrder, prev.id, prevData['order']);
                                    setState(() {});
                                  }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: index < docs.length - 1
                                      ? () async {
                                    final next = docs[index + 1];
                                    final nextData = next.data() as Map<String, dynamic>;
                                    await _swapOrders(doc.id, currentOrder, next.id, nextData['order']);
                                    setState(() {});
                                  }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteBanner(doc.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    _nameController.text = data['name'] ?? '';
                                    _urlController.text = data['url'] ?? '';
                                    _selectedDocId = doc.id;
                                    _isEditMode = true;
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

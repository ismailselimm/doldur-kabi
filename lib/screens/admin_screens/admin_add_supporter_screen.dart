import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class AdminAddSupporterScreen extends StatefulWidget {
  const AdminAddSupporterScreen({super.key});

  @override
  State<AdminAddSupporterScreen> createState() =>
      _AdminAddSupporterScreenState();
}

class _AdminAddSupporterScreenState extends State<AdminAddSupporterScreen> {
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  String? _selectedCategory;
  File? _selectedImage;
  bool _isLoading = false;
  String? _editingSupporterId;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadSupporter() async {
    if (_nameController.text.isEmpty || _selectedCategory == null) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ref = FirebaseStorage.instance
            .ref()
            .child('supporters/${DateTime.now().millisecondsSinceEpoch}.png');

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/png'),
        );

        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final dataToSave = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory!.capitalize(),
        'website': _websiteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        dataToSave['imageUrl'] = imageUrl;
      }

      if (_editingSupporterId != null) {
        // 🔁 Güncelleme
        await FirebaseFirestore.instance
            .collection('supporters')
            .doc(_editingSupporterId)
            .update(dataToSave);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Destekçi güncellendi ✅")));
      } else {
        // ➕ Yeni ekleme
        await FirebaseFirestore.instance
            .collection('supporters')
            .add(dataToSave);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Destekçi eklendi ✅")));
      }

      _nameController.clear();
      _websiteController.clear();
      setState(() {
        _selectedImage = null;
        _selectedCategory = null;
        _editingSupporterId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
    setState(() => _isLoading = false);
  }

  void _loadForEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _websiteController.text = data['website'] ?? '';
    _selectedCategory = (data['category'] ?? '').toString().toLowerCase();
    _selectedImage = null;
    _editingSupporterId = doc.id;
    setState(() {});
  }

  Future<void> _deleteSupporter(String id) async {
    await FirebaseFirestore.instance.collection('supporters').doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Destekçi silindi ❌")));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Destekçi Ekle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF9346A1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Destekçi Bilgileri",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Destekçi Adı",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: const Text("Kategori Seçin"),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'elmas', child: Text('💎 Elmas')),
                        DropdownMenuItem(
                            value: 'altin', child: Text('🥇 Altın')),
                        DropdownMenuItem(
                            value: 'gumus', child: Text('🥈 Gümüş')),
                        DropdownMenuItem(
                            value: 'reklam', child: Text('📣 Reklam')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: "Web Sitesi (opsiyonel)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!,
                                height: 140, fit: BoxFit.cover),
                          )
                        : Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image,
                                size: 50, color: Colors.grey),
                          ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Logo Seç"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                onPressed: _uploadSupporter,
                                icon: Icon(_editingSupporterId == null
                                    ? Icons.save
                                    : Icons.edit),
                                label: Text(_editingSupporterId == null
                                    ? "Kaydet"
                                    : "Güncelle"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _editingSupporterId == null
                                      ? Colors.green
                                      : Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Mevcut Destekçiler",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('supporters')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Text("Henüz destekçi eklenmemiş.");
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(data['name'] ?? ''),
                          subtitle: Text("Kategori: ${data['category'] ?? ''}"
                              "${(data['website'] ?? '').isNotEmpty ? '\nWeb: ${data['website']}' : ''}"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'sil') {
                                _deleteSupporter(doc.id);
                              } else if (val == 'güncelle') {
                                _loadForEdit(doc);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'güncelle', child: Text("Güncelle")),
                              PopupMenuItem(value: 'sil', child: Text("Sil")),
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
        ));
  }
}

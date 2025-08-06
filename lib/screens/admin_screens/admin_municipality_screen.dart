import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAddMunicipalityScreen extends StatefulWidget {
  const AdminAddMunicipalityScreen({super.key});

  @override
  State<AdminAddMunicipalityScreen> createState() =>
      _AdminAddMunicipalityScreenState();
}

class _AdminAddMunicipalityScreenState
    extends State<AdminAddMunicipalityScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _editingMunicipalityId;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadMunicipality() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ref = FirebaseStorage.instance.ref().child(
            'municipalities/${DateTime.now().millisecondsSinceEpoch}.png');

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/png'),
        );

        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final dataToSave = {
        'name': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (imageUrl != null) dataToSave['imageUrl'] = imageUrl;

      if (_editingMunicipalityId != null) {
        await FirebaseFirestore.instance
            .collection('municipalities')
            .doc(_editingMunicipalityId)
            .update(dataToSave);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Belediye güncellendi ✅")));
      } else {
        await FirebaseFirestore.instance
            .collection('municipalities')
            .add(dataToSave);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Belediye eklendi ✅")));
      }

      _nameController.clear();
      setState(() {
        _selectedImage = null;
        _editingMunicipalityId = null;
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
    _selectedImage = null;
    _editingMunicipalityId = doc.id;
    setState(() {});
  }

  Future<void> _deleteMunicipality(String id) async {
    await FirebaseFirestore.instance
        .collection('municipalities')
        .doc(id)
        .delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Belediye silindi ❌")));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Belediye Ekle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    const Text("Belediye Bilgileri",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Belediye Adı",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        hintText: "Örn: Sarıyer Belediyesi",
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          icon: const Icon(Icons.upload_rounded),
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
                                onPressed: _uploadMunicipality,
                                icon: Icon(_editingMunicipalityId == null
                                    ? Icons.check
                                    : Icons.edit),
                                label: Text(_editingMunicipalityId == null
                                    ? "Kaydet"
                                    : "Güncelle"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _editingMunicipalityId == null
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
              const Text("Mevcut Belediyeler",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('municipalities')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Text("Henüz belediye eklenmemiş.");
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
                          leading: data['imageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const CircleAvatar(child: Icon(Icons.image)),
                          title: Text(data['name'] ?? ''),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'sil') {
                                _deleteMunicipality(doc.id);
                              } else if (val == 'guncelle') {
                                _loadForEdit(doc);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'guncelle', child: Text("Güncelle")),
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
        )
    );
  }
}

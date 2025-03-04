import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _selectedImage;
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// **🔥 Galeriden resim seç**
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      print("📷 Seçilen resim: ${_selectedImage!.path}");
    }
  }

  /// **🔥 Resmi Firebase Storage'a yükleyip URL döndür**
  Future<void> _uploadImage() async {
    await FirebaseAuth.instance.currentUser?.reload();
    User? user = FirebaseAuth.instance.currentUser;
    if (_selectedImage == null || user == null) {
      print("❌ Kullanıcı giriş yapmamış!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Storage için dosya yolu
      String filePath = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print("📁 Dosya yolu: $filePath");

      final storageRef = FirebaseStorage.instance.ref().child(filePath);


      // Yükleme tamamlanınca URL al
      TaskSnapshot snapshot = await storageRef.putFile(_selectedImage!);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("✅ Resim yüklendi: $downloadUrl");



      print("✅ Profil resmi güncellendi.");
    } catch (e, stacktrace) {
      print("🔥 HATA: $e");
      print("🔍 Stacktrace: $stacktrace");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Gönderi Paylaş',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.purple[300]),
                    const SizedBox(height: 8),
                    Text(
                      "Fotoğraf Ekle",
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedImage!, width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                controller: _postController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ne paylaşmak istersin?",
                  hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_selectedImage != null) await _uploadImage();
              },
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Paylaş"),
            ),
          ],
        ),
      ),
    );
  }
}

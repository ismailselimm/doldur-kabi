import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 📌 NAVIGATION BAR İÇİN GEREKEN SAYFA
import 'package:doldur_kabi/screens/community_screens/community_screen.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _selectedImage;
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  /// **🔥 Galeriden resim seç ve sıkıştır**
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage != null) {
      File compressedFile = File(pickedFile.path)
        ..writeAsBytesSync(img.encodeJpg(originalImage, quality: 75));

      setState(() {
        _selectedImage = compressedFile;
      });
    }
  }

  /// **🔥 Resmi Firebase Storage'a yükleyip URL döndür**
  /// **🔥 Resmi Firebase Storage'a yükleyip URL döndür**
  Future<void> _uploadImage() async {
    if (_selectedImage == null || user == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String filePath = 'posts/postImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      Uint8List fileData = await _selectedImage!.readAsBytes();
      TaskSnapshot snapshot = await storageRef.putData(fileData);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // **🔥 1️⃣ Gönderiyi Firestore'a ekleyelim**
      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': downloadUrl,
        'description': _postController.text,
        'createdAt': Timestamp.now(),
        'userId': user?.uid,
        'username': user?.displayName ?? 'Unknown',
        'userImage': user?.photoURL ?? 'assets/images/default_avatar.png',
        'likes': 0,
        'comments': 0,
      });

      // **🔥 2️⃣ Kullanıcının gönderi sayısını artır**
      String userId = user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'gonderiSayisi': FieldValue.increment(1),
      });

      // ✅ Post paylaşıldıktan sonra Community ekranına yönlendir
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );

      print("✅ Gönderi başarıyla eklendi ve kullanıcı profili güncellendi!");
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
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // **🔥 Resim Yükleme Alanı**
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 60, color: Colors.grey[500]),
                    const SizedBox(height: 10),
                    Text(
                      "Fotoğraf Ekle",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(_selectedImage!,
                      width: double.infinity, height: 220, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // **🔥 Açıklama Alanı**
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _postController,
                maxLines: 4,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Ne paylaşmak istersin?",
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // **🔥 Paylaş Butonu**
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_selectedImage != null) await _uploadImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9346A1), // Canlı Mor Tonu
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                elevation: 4,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                "Paylaş",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

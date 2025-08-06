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
import 'package:doldur_kabi/screens/home_screens/main_home_page.dart';


// 📌 NAVIGATION BAR İÇİN GEREKEN SAYFA
import 'package:doldur_kabi/screens/community_screens/community_screen.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  List<File> _selectedImages = [];
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();



  /// **🔥 Galeriden resim seç ve sıkıştır**
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _showErrorSnackBar("En fazla 3 fotoğraf yükleyebilirsiniz.");
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      final remainingSlots = 3 - _selectedImages.length;
      final selected = pickedFiles.take(remainingSlots).map((x) => File(x.path));

      setState(() {
        _selectedImages.addAll(selected);
      });
    }
  }

  /// **🔥 Resmi Firebase Storage'a yükleyip URL döndür**
  Future<void> _uploadImage() async {
    if (_selectedImages.isEmpty || user == null) return;

    List<String> uploadedUrls = [];
    for (File imgFile in _selectedImages) {
      Uint8List fileData = await imgFile.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts/postImage_${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(imgFile)}.jpg');
      final snapshot = await ref.putData(fileData);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      uploadedUrls.add(downloadUrl);
    }



    setState(() => _isLoading = true);

    try {
      String filePath = 'posts/postImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrls': uploadedUrls,
        'description': _postController.text,
        'createdAt': Timestamp.now(),
        'userId': user?.uid,
        'username': user?.displayName ?? 'Unknown',
        'userImage': user?.photoURL ?? '',
        'likes': 0,
        'comments': 0,
        'cityDistrict': "${_cityController.text.trim()} - ${_districtController.text.trim()}",
        'isApproved': false, // 🔥 Onay sistemi için eklendi

      });


      String userId = user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'gonderiSayisi': FieldValue.increment(1),
      });

      // ✅ Önce sayfayı kapat
      Navigator.pop(context);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.hourglass_top, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Gönderin onaylandığında yayınlanacak!",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF9346A1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          elevation: 6,
          duration: const Duration(seconds: 3),
        ),
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
              onTap: _pickImages,
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
                  child: _selectedImages.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 60, color: Colors.grey[500]),
                      const SizedBox(height: 10),
                      Text("Fotoğraf Ekle", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    ],
                  )
                      : SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  color: Colors.grey[300],
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "**Bir gönderide en fazla 3 fotoğraf paylaşabilirsiniz.\n"
                  "Birden fazla fotoğraf paylaşırken yatay fotoğrafları yatay fotoğraflarla,"
                  " dikey fotoğrafları dikey fotoğraflarla paylaşmanız önerilir. ",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
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

            // 🔷 İl - İlçe Alanı
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // İl input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              hintText: "İl",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // İlçe input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _districtController,
                            decoration: const InputDecoration(
                              hintText: "İlçe",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // **🔥 Paylaş Butonu**
            ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true); // 🔥 Loading hemen başlasın

                  if (_selectedImages.isEmpty) {
                    _showErrorSnackBar("Lütfen bir fotoğraf ekleyin!");
                    setState(() => _isLoading = false); // ❌ Hata varsa loading kapansın
                    return;
                  }

                  if (_cityController.text.trim().isEmpty || _districtController.text.trim().isEmpty) {
                    _showErrorSnackBar("Lütfen il ve ilçe bilgisini doldurun!");
                    setState(() => _isLoading = false); // ❌ Hata varsa loading kapansın
                    return;
                  }

                  await _uploadImage(); // ✅ Başarılıysa loading zaten içeride kapanıyor
                },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9346A1), // Canlı Mor Tonu
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
                  : const Text(
                "Paylaş",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }


}

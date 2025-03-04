import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AddLostPetScreen extends StatefulWidget {
  @override
  _AddLostPetScreenState createState() => _AddLostPetScreenState();
}

class _AddLostPetScreenState extends State<AddLostPetScreen> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPetType = "Kedi"; // Varsayılan olarak kedi seçili
  File? _selectedImage; // Kullanıcının seçtiği resim
  bool _isLoading = false;

  // Resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitLostPet() async {
    if (_petNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _phoneController.text.isEmpty) { // Fotoğraf zorunlu olmaktan çıktı!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;

    try {
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(_selectedImage!);
        if (imageUrl == null) {
          print("DEBUG ERROR: Fotoğraf yüklenemedi, ilana fotoğraf eklenmeyecek.");
        }
      } else {
        print("DEBUG: Kullanıcı fotoğraf eklemedi.");
      }

      await FirebaseFirestore.instance.collection('lost_pets').add({
        'petName': _petNameController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'petType': _selectedPetType,
        'imageUrl': imageUrl, // Eğer fotoğraf yoksa null olarak kaydolur
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıp ilanı başarıyla eklendi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("DEBUG ERROR: Kayıp ilanı eklenirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<String?> _uploadImageToStorage(File image) async {
    try {
      String fileName = const Uuid().v4();
      Reference storageRef =
      FirebaseStorage.instance.ref().child('lost_pets/$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("DEBUG: Fotoğraf başarıyla yüklendi: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("DEBUG ERROR: Fotoğraf yükleme hatası: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kayıp Hayvan İlanı Ver',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlan Türü Seçimi
                Text(
                  "İlan Türü",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPetTypeButton("Kedi"),
                    const SizedBox(width: 12),
                    _buildPetTypeButton("Köpek"),
                  ],
                ),
                const SizedBox(height: 20),

                // Hayvanın Adı
                _buildTextField("Hayvanın Adı", _petNameController),

                // Adres Bilgisi
                _buildTextField("Nerede Kayboldu? (İl-İlçe Şeklinde)", _locationController),

                // Telefon Numarası
                _buildTextField("İletişim Numarası", _phoneController, keyboardType: TextInputType.phone),

                const SizedBox(height: 20),

                // Resim Yükleme Kartı
                _buildCard(
                  title: "Fotoğraf Yükle",
                  isImage: true,
                ),

                const SizedBox(height: 20),

                // Kaydet Butonu
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitLostPet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23B14D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "İlanı Kaydet",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Kedi / Köpek Seçenekleri
  Widget _buildPetTypeButton(String type) {
    bool isSelected = _selectedPetType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetType = type;
        });
      },
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, bool isImage = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isImage)
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage == null
                    ? Container(
                  height: 150,
                  width: double.infinity,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Fotoğraf Yükle", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: 150),
                ),
              ),
          ],
        ),
      ),
    );
  }


  // Input Alanları
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  User? user;
  File? _image;
  String? _profileUrl;
  bool _isLoading = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _createUserIfNotExists();
      _fetchUserData();
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = "${dir.path}/compressed.jpg";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // 📌 Kaliteyi düşür (70 ideal)
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _createUserIfNotExists() async {
    if (user == null) return;

    DocumentReference userDoc = _firestore.collection('users').doc(user!.uid);

    try {
      var doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'firstName': '',
          'lastName': '',
          'profileUrl': '',
          'email': user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("❌ HATA: Kullanıcı Firestore'a eklenirken oluştu: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      var userDoc = await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data();
        setState(() {
          _firstNameController.text = data?['firstName'] ?? "";
          _lastNameController.text = data?['lastName'] ?? "";
          _profileUrl = data?['profileUrl'];
        });
      }
    } catch (e) {
      print("❌ HATA: Kullanıcı verisi çekilirken oluştu: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || user == null) {
      print("❌ HATA: Resim seçilmedi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      File? compressedImage = await _compressImage(_image!); // 📌 Sıkıştırılmış dosya

      if (compressedImage == null) {
        print("❌ HATA: Resim sıkıştırılamadı!");
        return;
      }

      String safeUID = user!.uid;
      String filePath = 'profile_pictures/$safeUID.jpg';

      final ref = FirebaseStorage.instance.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(compressedImage); // 📌 Küçültülmüş resim yükleniyor

      uploadTask.snapshotEvents.listen((event) {
        print("📡 Yükleme Durumu: ${event.state}");
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _profileUrl = downloadUrl;
      });

      // ✅ **Firestore'da profil fotoğrafını güncelle**
      await _firestore.collection('users').doc(user!.uid).set(
        {'profileUrl': downloadUrl},
        SetOptions(merge: true),
      );

      print("✅ Firestore’da profil fotoğrafı güncellendi!");

      // ✅ **Firebase Authentication Profilini Güncelle**
      await user!.updatePhotoURL(downloadUrl);
      await user!.reload(); // Kullanıcı verisini yeniden yükle
      user = FirebaseAuth.instance.currentUser; // **Yeni user verisini ata!**

      print("✅ Firebase Authentication profili güncellendi: ${user!.photoURL}");

      // ✅ **Profil ekranına yönlendir ve sonucu gönder**
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      print("❌ HATA: Profil resmi yüklenirken hata oluştu: $e");
    }

    setState(() => _isLoading = false);
  }



  Future<void> _deleteProfilePicture() async {
    if (_profileUrl == null || _profileUrl!.isEmpty || user == null) {
      print("⚠️ Profil resmi zaten yok.");
      return;
    }

    setState(() => _isImageUploading = true);

    try {
      String safeUID = user!.uid;
      String filePath = 'profile_pictures/$safeUID.jpg';

      await FirebaseStorage.instance.ref().child(filePath).delete();

      await _firestore.collection('users').doc(user!.uid).set(
        {'profileUrl': ''},
        SetOptions(merge: true),
      );

      setState(() {
        _profileUrl = null;
      });

      print("✅ Profil resmi silindi!");
    } catch (e) {
      print("❌ HATA: Profil resmi silinirken hata oluştu: $e");
    }

    setState(() => _isImageUploading = false);
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      });

      print("✅ Kullanıcı bilgileri Firestore'da güncellendi!");

      // ✅ **Başarıyla güncellendiğinde Profil Ekranına yönlendir**
      if (mounted) {
        Navigator.pop(context, true); // Geri dönerken true döndür
      }
    } catch (e) {
      print("❌ Profil güncellenirken hata oluştu: $e");
    }

    setState(() => _isLoading = false);
  }


  @override
  // 📸 Kullanıcıya galeri veya kamera seçeneği sunan modal bottom sheet
  Widget _imagePickerOptions() {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kameradan Çek'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeriden Seç'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

// 📌 Ad ve Soyad için kullanılan textfield widget'ı
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profili Güncelle',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => _imagePickerOptions(),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : (_profileUrl != null && _profileUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_profileUrl!)
                        : const AssetImage('assets/images/avatar1.png')) as ImageProvider<Object>,
                  ),
                  if (_isImageUploading)
                    const CircularProgressIndicator(),

                  // ✨ Düzenleme İkonu Eklendi
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.shade700,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.pencil, // FontAwesome kullanıyorsan: FontAwesomeIcons.pen
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: _deleteProfilePicture,
              child: const Text("Profil Resmini Kaldır"),
            ),
            const SizedBox(height: 25),
            _buildTextField(_firstNameController, 'Ad'),
            const SizedBox(height: 12),
            _buildTextField(_lastNameController, 'Soyad'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: const Text(
                "Değişiklikleri Kaydet",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
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
      File? croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
        });
        await _uploadImage();
      }
    }
  }


  Future<void> _uploadImage() async {
    if (_image == null || user == null) {
      print("❌ HATA: Resim seçilmedi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      File? compressedImage = await _compressImage(_image!);
      if (compressedImage == null) {
        print("❌ HATA: Resim sıkıştırılamadı!");
        return;
      }

      final bytes = await compressedImage.readAsBytes();
      final String filePath = 'profile_pictures/${user!.uid}-${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(filePath);

      UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await uploadTask;
      String downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user!.uid).set(
        {'profileUrl': downloadUrl},
        SetOptions(merge: true),
      );

      await user!.updatePhotoURL(downloadUrl);
      await user!.reload();
      user = FirebaseAuth.instance.currentUser;

      setState(() {
        _profileUrl = downloadUrl;
      });

      print("✅ putData ile profil fotoğrafı yüklendi: $downloadUrl");

      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      print("❌ putData ile profil resmi yüklenemedi: $e");
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
      final fullName = '${_firstNameController.text} ${_lastNameController.text}';

      // 🔄 Firestore'daki verileri güncelle
      await _firestore.collection('users').doc(user!.uid).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      });

      // 🔄 Firebase Authentication displayName’i de güncelle
      await user!.updateDisplayName(fullName);
      await user!.reload(); // 🔁 Güncel kullanıcıyı çek
      user = FirebaseAuth.instance.currentUser;

      print("✅ Firestore ve FirebaseAuth displayName güncellendi!");

      if (mounted) {
        Navigator.pop(context, true); // Geri dönerken güncelleme olduğunu bildir
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profili Güncelle',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 Profil Fotoğrafı
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _imagePickerOptions(),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : (_profileUrl != null && _profileUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_profileUrl!)
                        : const AssetImage('assets/images/avatar1.png')) as ImageProvider<Object>,
                  ),
                  if (_isImageUploading)
                    const CircularProgressIndicator(),

                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF9346A1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        FontAwesomeIcons.pen,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: _deleteProfilePicture,
              child: const Text(
                "Profil Resmini Kaldır",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 🔤 Ad Soyad Alanları
            _buildStyledField(_firstNameController, 'Ad'),
            const SizedBox(height: 14),
            _buildStyledField(_lastNameController, 'Soyad'),
            const SizedBox(height: 30),

            // 💾 Kaydet Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                label: const Text(
                  "Değişiklikleri Kaydet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9346A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressQuality: 80,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.original,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Kırp',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Kırp',
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Widget _buildStyledField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }


}

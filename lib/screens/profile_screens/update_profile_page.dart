import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doldur_kabi/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user?.displayName != null) {
      List<String> names = user!.displayName!.split(' ');
      _firstNameController.text = names.isNotEmpty ? names[0] : "";
      _lastNameController.text = names.length > 1 ? names.sublist(1).join(' ') : "";
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || user == null) return;
    setState(() => _isLoading = true);
    try {
      String filePath = 'profile_pictures/${user!.uid}.jpg';
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(filePath).putFile(_image!);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      await user!.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profileUrl': downloadUrl});
      setState(() {});
    } catch (e) {
      print("Profil resmi yüklenirken hata oluştu: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      String fullName = "${_firstNameController.text} ${_lastNameController.text}".trim();
      await user!.updateDisplayName(fullName);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      });
      SelectedIndex.changeSelectedIndex(2);
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage()));
    } catch (e) {
      print("Profil güncellenirken hata oluştu: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[200],
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (user?.photoURL != null
                    ? CachedNetworkImageProvider(user!.photoURL!)
                    : const AssetImage('assets/images/avatar1.png')) as ImageProvider,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, color: Colors.purple),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            _buildTextField(_firstNameController, 'Ad'),
            const SizedBox(height: 12),
            _buildTextField(_lastNameController, 'Soyad'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_image != null) await _uploadImage();
                await _updateProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: const Text("Değişiklikleri Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

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
}

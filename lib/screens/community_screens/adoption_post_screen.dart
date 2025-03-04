import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AdoptionPostScreen extends StatefulWidget {
  @override
  _AdoptionPostScreenState createState() => _AdoptionPostScreenState();
}

class _AdoptionPostScreenState extends State<AdoptionPostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Kedi';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setOwnerName();
  }

  Widget _buildCard({
    required String title,
    String content = '',
    IconData? icon,
    bool isImage = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(icon, color: Colors.purple, size: 30),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            isImage
                ? GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                height: 150,
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
                child: Image.file(_image!,
                    fit: BoxFit.cover, width: double.infinity, height: 150),
              ),
            )
                : Text(content,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }


  Future<void> _setOwnerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _ownerNameController.text = user.displayName ?? "Bilinmiyor";
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85, // İlk sıkıştırma
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      print("DEBUG: Orijinal Fotoğraf Boyutu: ${imageFile.lengthSync()} byte");

      // Fotoğrafı sıkıştır ve yeni bir dosya oluştur
      File? compressedImage = await _compressImage(imageFile);

      setState(() {
        _image = compressedImage;
      });

      print("DEBUG: Sıkıştırılmış Fotoğraf Boyutu: ${_image!.lengthSync()} byte");
    } else {
      print("DEBUG: Fotoğraf seçme iptal edildi.");
    }
  }

// 📌 **Fotoğrafı sıkıştırma fonksiyonu**
  Future<File?> _compressImage(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${Random().nextInt(100000)}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 70, // Kaliteyi düşürerek boyutu küçült
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _submitPost() async {
    print("DEBUG: _submitPost metodu çağrıldı!");

    if (_formKey.currentState == null) {
      print("DEBUG ERROR: _formKey.currentState NULL! Form düzgün tanımlanmamış olabilir.");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print("DEBUG: Form doğrulama başarısız!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("DEBUG ERROR: Kullanıcı giriş yapmamış! FirebaseAuth.instance.currentUser NULL!");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen giriş yapın!")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print("DEBUG: Kullanıcı giriş yaptı! UID: ${user.uid}");
    String? imageUrl;

    try {
      if (_image == null) {
        print("DEBUG ERROR: _image NULL! Fotoğraf seçilmemiş!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen bir fotoğraf seçin!")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("DEBUG: Fotoğraf yükleme başlatılıyor...");
      imageUrl = await _uploadImageToStorage(_image!);
      print("DEBUG: Fotoğraf yüklendi: $imageUrl");

      print("DEBUG: Firestore'a ilan ekleniyor...");
      await _savePostToFirestore(user.uid, imageUrl);
      print("DEBUG: Firestore'a ilan başarıyla kaydedildi!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlan başarıyla oluşturuldu!")),
      );

      print("DEBUG: Kullanıcı geri yönlendirilecek.");
      Navigator.pop(context);
    } catch (e) {
      print("DEBUG ERROR: Bir hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print("DEBUG: _submitPost tamamlandı.");
    }
  }

  Future<String?> _uploadImageToStorage(File image) async {
    try {
      print("DEBUG: Fotoğraf yükleme başladı...");
      String fileName = const Uuid().v4();
      Reference storageRef =
      FirebaseStorage.instance.ref().child('adoption_posts/$fileName.jpg');

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


  Future<void> _savePostToFirestore(String userId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('adoption_posts').add({
        'ownerId': userId,
        'ownerName': _ownerNameController.text,
        'animalType': _selectedType,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Firestore'a kaydetme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İlan Ver',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9346A1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // FORM KEY BAĞLANDI!
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimalOption("Kedi", "assets/images/cat.png", "Kedi"),
                  const SizedBox(width: 16),
                  _buildAnimalOption("Köpek", "assets/images/dog.png", "Köpek"),
                ],
              ),
              const SizedBox(height: 20),
              _buildCard(
                title: "İlan Sahibi",
                content: _ownerNameController.text,
                icon: Icons.person,
              ),
              const SizedBox(height: 15),
              _buildDescriptionCard(),
              const SizedBox(height: 15),
              _buildCard(
                title: "Fotoğraf Yükle",
                isImage: true,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Onaya Gönder",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalOption(String label, String imagePath, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        width: 80,
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedType == value ? Colors.purple : Colors.transparent,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 40, height: 40),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Colors.purple, size: 30),
                SizedBox(width: 12),
                Text(
                  "İlan Açıklaması",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: "Açıklama Giriniz.",
                filled: true,
                fillColor: Colors.white30,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Bu alan zorunludur';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
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
  String? _selectedCity;
  final List<String> _cities = [
    "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın",
    "Balıkesir", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı",
    "Çorum", "Denizli", "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep",
    "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Isparta", "Mersin", "İstanbul", "İzmir", "Kars",
    "Kastamonu", "Kayseri", "Kırklareli", "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
    "Kahramanmaraş", "Mardin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Rize", "Sakarya",
    "Samsun", "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Şanlıurfa",
    "Uşak", "Van", "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman", "Kırıkkale", "Batman",
    "Şırnak", "Bartın", "Ardahan", "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
  ];



  @override
  void initState() {
    super.initState();
    _setOwnerName();
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
      imageQuality: 85,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      File? compressedImage = await _compressImage(imageFile);
      setState(() {
        _image = compressedImage;
      });
    }
  }

  Future<File?> _compressImage(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${Random().nextInt(100000)}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 70,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen giriş yapın!")));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir fotoğraf seçin!")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String imageUrl = await _uploadImageToStorage(_image!);
      await _savePostToFirestore(user, imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlan başarıyla oluşturuldu!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImageToStorage(File image) async {
    String fileName = const Uuid().v4();
    Reference storageRef =
    FirebaseStorage.instance.ref().child('adoption_posts/$fileName.jpg');

    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _savePostToFirestore(User user, String imageUrl) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await FirebaseFirestore.instance.collection('adoption_posts').add({
      'ownerId': user.uid,
      'ownerEmail': user.email,
      'ownerName': _ownerNameController.text,
      'ownerProfileUrl': userData?['profileUrl'], // 🔥 Profil fotoğrafını Firestore'a ekle
      'animalType': _selectedType,
      'description': _descriptionController.text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'city': _selectedCity ?? "Belirtilmemiş",
    });
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
          key: _formKey,
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
              _buildOwnerCard(), // 🔥 İlan Sahibi Kartı **TAM GENİŞLİKTE**
              const SizedBox(height: 15),
              _buildDescriptionCard(),
              const SizedBox(height: 15),
              _buildCityDropdown(),
              const SizedBox(height: 15),
              _buildPhotoUploadCard(), // 🔥 Fotoğraf Yükleme Alanı Güncellendi
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "İlan Paylaş",
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

  Widget _buildCityDropdown() {
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
                Icon(Icons.location_city, color: Colors.purple, size: 30),
                SizedBox(width: 12),
                Text(
                  "Şehir Seç",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                hint: const Text("Şehir seçiniz", style: TextStyle(color: Colors.grey)),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                value: _selectedCity,
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value as String?;
                  });
                },
                buttonStyleData: const ButtonStyleData(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildOwnerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.purple, size: 30),
        title: Text(_ownerNameController.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 180,
          alignment: Alignment.center,
          child: _image == null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text("Fotoğraf Yükle", style: TextStyle(color: Colors.grey)),
            ],
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
      ),
    );
  }

  // 🐾 **Kedi / Köpek Seçim Butonları**
  Widget _buildAnimalOption(String label, String imagePath, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedType == value ? Colors.purple : Colors.grey[300]!,
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
            Image.asset(imagePath, width: 50, height: 50), // 🖼️ İkon
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

// 📝 **İlan Açıklaması Kartı**
  Widget _buildDescriptionCard() {
    return Card(
      elevation: 4,
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
              maxLines: 2,
              maxLength: 400,
              decoration: InputDecoration(
                hintText: "Açıklama Giriniz.",
                border: InputBorder.none, // 🔥 Alt çizgiyi kaldırır
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

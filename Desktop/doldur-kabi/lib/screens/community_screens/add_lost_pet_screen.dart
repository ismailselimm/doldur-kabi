import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class AddLostPetScreen extends StatefulWidget {
  @override
  _AddLostPetScreenState createState() => _AddLostPetScreenState();
}

class _AddLostPetScreenState extends State<AddLostPetScreen> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<File> _selectedImages = [];
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPetType = "Kedi";
  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedCity = "İstanbul"; // Varsayılan olarak İstanbul seçili olacak
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

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
    }
  }


  @override
  void initState() {
    super.initState();
    debugPrint("Kayıp İlan Ver Sayfası Açıldı"); // Debugging
  }


  Future<void> _submitLostPet() async {
    if (_petNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun ve en az 1 fotoğraf ekleyin!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> uploadedImageUrls = [];

    try {
      // 🔥 Her resmi sıkıştırıp yükle, URL'yi listeye ekle
      for (File image in _selectedImages) {
        final url = await _uploadImageToStorage(image);
        if (url != null) uploadedImageUrls.add(url);
      }

      if (uploadedImageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fotoğraflar yüklenirken bir hata oluştu.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 🔥 Firestore'a ilan ekle
      await FirebaseFirestore.instance.collection('lost_pets').add({
        'petName': _petNameController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'petType': _selectedPetType,
        'city': _selectedCity,
        'imageUrls': uploadedImageUrls, // 🔥 Çoklu URL kaydı
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıp ilanı başarıyla eklendi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("❌ HATA: Firestore’a kaydetme hatası: $e");
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
      print("📡 Fotoğraf sıkıştırılıyor...");
      File? compressedImage = await _compressImage(image);

      if (compressedImage == null || !(await compressedImage.exists())) {
        print("❌ HATA: Sıkıştırılmış dosya yok!");
        return null;
      }

      print("📡 Fotoğraf yükleme başladı...");
      String fileName = const Uuid().v4();
      Reference storageRef = FirebaseStorage.instance.ref().child('lost_pets/$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(compressedImage);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print("✅ Fotoğraf başarıyla yüklendi: $downloadUrl");
        return downloadUrl;
      } else {
        print("❌ HATA: Upload başarısız oldu snapshot.state = ${snapshot.state}");
        return null;
      }
    } catch (e) {
      print("❌ HATA: Fotoğraf yükleme hatası: $e");
      return null;
    }
  }



  Future<File?> _compressImage(File imageFile) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg'; // 🔥 random düzgün isim

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 80, // çok düşük kalite verme, 80 olsun
        format: CompressFormat.jpeg, // 🔥 formatı açık açık söyle JPEG olsun
      );

      if (result == null) {
        print("❌ compressAndGetFile null döndü!");
        return null;
      }

      print("✅ Sıkıştırma başarılı: ${result.path}");
      return File(result.path);
    } catch (e) {
      print("❌ Sıkıştırma sırasında hata: $e");
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12), // 🔥 Araya boşluk ekle
                _buildCityDropdown(), // 🔥 Şehir dropdown’u alta alındı
                const SizedBox(height: 20),
                _buildTextField("Hayvanın Adı", _petNameController),
                _buildTextField("Nerede Kayboldu? (İl-İlçe Şeklinde)", _locationController),
                _buildTextField("İletişim Numarası", _phoneController, keyboardType: TextInputType.phone),
                _buildTextField("Açıklama (isteğe bağlı)", _descriptionController, keyboardType: TextInputType.multiline),
                const SizedBox(height: 20),
                _buildImageUploadCard(),
                const SizedBox(height: 20),
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
                      "İlanı Paylaş",
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

  Widget _buildCityDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade400, width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Colors.purple),
        items: _cities.map((city) {
          return DropdownMenuItem<String>(
            value: city,
            child: Text(city, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCity = value!;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none, // Çerçeveyi kaldır
        ),
        menuMaxHeight: 200, // 🔥 **Dropdown'un max yüksekliğini 3-4 şehir gösterecek şekilde sınırla**
      ),
    );
  }

  Widget _buildCityInfoText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        "$_selectedCity şehrinde kayıp ilanı veriyorsunuz",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.w500),
      ),
    );
  }


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

  Widget _buildImageUploadCard() {
    return GestureDetector(
      onTap: _pickImages,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("Fotoğrafları Yükle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _selectedImages.isEmpty
                  ? Column(
                children: const [
                  Icon(Icons.add_photo_alternate, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("Fotoğraf Seç", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              )
                  : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImages[index], width: 150, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

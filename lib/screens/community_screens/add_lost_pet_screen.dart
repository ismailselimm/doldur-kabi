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
    "Adana", "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya", "Ankara", "Antalya", "Artvin", "Aydın",
    "Balıkesir", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı",
    "Çorum", "Denizli", "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep",
    "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Isparta", "Mersin", "İstanbul", "İzmir", "Kars",
    "Kastamonu", "Kayseri", "KKTC (Kıbrıs)","Kırklareli", "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
    "Kahramanmaraş", "Mardin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Rize", "Sakarya",
    "Samsun", "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Şanlıurfa",
    "Uşak", "Van", "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman", "Kırıkkale", "Batman",
    "Şırnak", "Bartın", "Ardahan", "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
  ];

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _showErrorSnackBar("En fazla 3 fotoğraf yükleyebilirsiniz.");
      return;
    }

    final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      final remainingSlots = 3 - _selectedImages.length;
      final selectedFiles = pickedFiles.take(remainingSlots).map((xfile) => File(xfile.path));

      setState(() {
        _selectedImages.addAll(selectedFiles);
      });
    }
  }



  @override
  void initState() {
    super.initState();
    debugPrint("Kayıp İlan Ver Sayfası Açıldı"); // Debugging
  }


  Future<void> _submitLostPet() async {
    if (_petNameController.text.isEmpty) {
      _showErrorSnackBar("Lütfen hayvanın adını girin.");
      return;
    }
    if (_locationController.text.isEmpty) {
      _showErrorSnackBar("Lütfen nerede kaybolduğunu girin.");
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar("Lütfen iletişim numarasını girin.");
      return;
    }
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar("Lütfen en az 1 fotoğraf ekleyin.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> uploadedImageUrls = [];

    try {
      for (File image in _selectedImages) {
        final url = await _uploadImageToStorage(image);
        if (url != null) uploadedImageUrls.add(url);
      }

      if (uploadedImageUrls.isEmpty) {
        _showErrorSnackBar("Fotoğraflar yüklenirken bir hata oluştu.");
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('lost_pets').add({
        'petName': _petNameController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'petType': _selectedPetType,
        'city': _selectedCity,
        'imageUrls': uploadedImageUrls,
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'isApproved': false, // ✅ Admin onay sistemi
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.hourglass_top, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "İlanınız onaya gönderildi. En kısa sürede yayınlanacaktır.",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      _showErrorSnackBar("Bir hata oluştu: $e");
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

      final bytes = await compressedImage.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final fileName = const Uuid().v4();

      Reference ref = FirebaseStorage.instance.ref().child('lost_pets/$fileName.jpg');
      UploadTask uploadTask = ref.putData(bytes, metadata);

      final snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("✅ putData ile başarıyla yüklendi: $downloadUrl");
        return downloadUrl;
      } else {
        print("❌ HATA: putData başarısız");
        return null;
      }
    } catch (e) {
      print("❌ HATA: putData sırasında hata: $e");
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
                    Expanded(child: _buildPetTypeButton("Kedi")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPetTypeButton("Köpek")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPetTypeButton("Kuş")),
                  ],
                ),
                const SizedBox(height: 12), // 🔥 Araya boşluk ekle
                _buildCityPickerButton(),
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

  Widget _buildCityPickerButton() {
    return GestureDetector(
      onTap: () => _showCityPickerBottomSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade400, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCity ?? "Şehir Seçin",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.purple),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "En fazla 3 fotoğraf yükleyebilirsiniz.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        GestureDetector(
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
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 1, // kare gibi kutu
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover, // istersen BoxFit.contain da olur
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
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
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCityPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9F4FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: ListView.separated(
            itemCount: _cities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final city = _cities[index];
              return ListTile(
                title: Text(city, style: GoogleFonts.poppins(fontSize: 16)),
                onTap: () {
                  setState(() {
                    _selectedCity = city;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

}

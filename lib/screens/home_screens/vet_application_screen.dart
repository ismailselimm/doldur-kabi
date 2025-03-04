import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VetApplicationScreen extends StatefulWidget {
  @override
  _VetApplicationScreenState createState() => _VetApplicationScreenState();
}

class _VetApplicationScreenState extends State<VetApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isVolunteer = false;
  bool _isSubmitting = false; // 🔥 Başvuru sırasında butonu kapatmak için

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true; // 🔥 Başvuru işlemi başladı
    });

    try {
      await FirebaseFirestore.instance.collection('vetApplications').add({
        'businessName': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'isVolunteer': _isVolunteer,
        'status': 'pending', // 🔥 Başvurunun durumunu takip etmek için
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başvurunuz onaya gönderildi!")),
      );

      Navigator.pop(context); // Başvuru tamamlanınca ekranı kapat
    } catch (e) {
      print("❌ Firebase Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başvuru sırasında hata oluştu, tekrar deneyin.")),
      );
    }

    setState(() {
      _isSubmitting = false; // 🔥 İşlem tamamlandı
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Veteriner Başvurusu',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("İşletme İsmi", _nameController, Icons.business),
              const SizedBox(height: 15),
              _buildTextField("Adres", _addressController, Icons.location_on),
              const SizedBox(height: 15),
              _buildTextField("Telefon Numarası", _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              CheckboxListTile(
                title: Text("Gönüllü olarak başvuruyorum", style: GoogleFonts.poppins(fontSize: 16)),
                value: _isVolunteer,
                onChanged: (bool? value) {
                  setState(() {
                    _isVolunteer = value!;
                  });
                },
                activeColor: const Color(0xFF9346A1),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isVolunteer && !_isSubmitting ? _submitApplication : null, // 🔥 Sadece gönüllü seçildiyse aktif
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVolunteer ? Colors.purple[700] : Colors.grey, // 🔥 Gönüllü değilse gri
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white) // 🔥 Yüklenme göstergesi
                      : const Text("Başvuruyu Gönder", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan zorunludur';
        }
        if (label == "Telefon Numarası" && (value.length < 10 || value.length > 13)) {
          return 'Geçerli bir telefon numarası girin';
        }
        return null;
      },
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ShelterApplicationScreen extends StatefulWidget {
  const ShelterApplicationScreen({super.key});

  @override
  State<ShelterApplicationScreen> createState() => _ShelterApplicationScreenState();
}

class _ShelterApplicationScreenState extends State<ShelterApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('shelterApplications').add({
        'shelterName': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'notes': _notesController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text("Başvuru Alındı"),
            ],
          ),
          content: const Text(
            "Başvurunuz başarıyla iletildi.\nEkibimiz en kısa sürede sizinle iletişime geçecektir.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog kapanır
                Navigator.pop(context); // form ekranı kapanır
              },
              child: const Text("Tamam", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      _formKey.currentState?.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Belediye Başvurusu', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF9346A1),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Belediyenizi / Barınağınızı uygulamamıza dahil etmek için aşağıdaki formu doldurabilir veya doğrudan\n📧 ",
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
                    ),
                    TextSpan(
                      text: 'ismailselimgarip@gmail.com',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.teal,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'ismailselimgarip@gmail.com',
                            query: Uri.encodeFull('subject=Belediye / Barınak Başvurusu&body=Merhaba Selim,\n\nBarınağımızı uygulamaya eklemek istiyoruz. Bilgilerimiz şu şekilde:'),
                          );
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          }
                        },
                    ),
                    TextSpan(
                      text: " (tıklayarak) \nadresine e-posta gönderebilirsiniz.",
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildField(label: "Barınak / Kurum Adı", controller: _nameController),
              _buildField(label: "Şehir", controller: _cityController),
              _buildField(label: "Yetkili Kişi Adı", controller: _contactPersonController),
              _buildField(label: "Telefon Numarası", controller: _phoneController, keyboardType: TextInputType.phone),
              _buildField(label: "E-Posta Adresi", controller: _emailController, keyboardType: TextInputType.emailAddress),
              _buildField(label: "Açıklama / Notlar", controller: _notesController, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  label: Text("Gönder", style: GoogleFonts.poppins(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9346A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (val) => (val == null || val.trim().isEmpty) ? "Bu alan boş bırakılamaz" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

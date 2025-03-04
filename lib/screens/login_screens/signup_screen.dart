import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../home_screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şifreler uyuşmuyor!")),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName("$_firstName $_lastName");
        await user.reload();
        user = _auth.currentUser;
        print("Kullanıcı güncellendi: ${user?.displayName}");
        await _firestore.collection('users').doc(user?.uid).set({
          'firstName': _firstName,
          'lastName': _lastName,
          'email': _email,
          'password': _password,
          'createdAt': Timestamp.now(),
          'profileUrl': null,
        });

        _showWelcomeDialog(user!);
      }
    } catch (e) {
      print("Firebase Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  void _showWelcomeDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              "Hoş Geldiniz 🥳",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sevgili ${user.displayName},\n\nDoldurKabı ailesine katıldığınız için çok mutluyuz! "
                    "Hayvan dostlarımız için harika işler yapmaya hazırız. 💜",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Devam Et"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7823B1), Color(0xFFB3C7EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  _buildTextFields(),
                  const SizedBox(height: 20),
                  _buildSignUpButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Kayıt Ol',
      style: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildTextField('Ad', (value) => _firstName = value!, Icons.person),
        _buildTextField('Soyad', (value) => _lastName = value!, Icons.person_outline),
        _buildTextField('E-posta', (value) => _email = value!, Icons.email, TextInputType.emailAddress),
        _buildTextField('Şifre', (value) => _password = value!, Icons.lock, TextInputType.visiblePassword, true),
        _buildTextField('Şifre Tekrar', (value) => _confirmPassword = value!, Icons.lock_outline, TextInputType.visiblePassword, true),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      child: const Text('Kaydol', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved, IconData icon,
      [TextInputType keyboardType = TextInputType.text, bool obscureText = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70), // Yazıyı beyaz yap
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(icon, color: Colors.white), // Yanına ikon ekle
        ),
        style: const TextStyle(color: Colors.white),
        onSaved: onSaved,
        validator: (value) => value == null || value.isEmpty ? 'Lütfen $label girin' : null,
      ),
    );
  }
}
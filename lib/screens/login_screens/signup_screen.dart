import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final TextEditingController _birthYearController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;




  // Form verileri
  String? _firstName, _lastName, _email, _tc, _birthYear, _institution;
  String? _phone, _password, _confirmPassword;
  File? _selectedImage;
  String? _profileUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ImagePicker _picker = ImagePicker();

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 🔐 Şifre eşleşme kontrolü burada yapılmalı
      if (_currentPage == 1 && _password != _confirmPassword) {
        setState(() {}); // rebuild for possible error UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Şifreler uyuşmuyor"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_currentPage < 2) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
        setState(() => _currentPage++);
      } else {
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lütfen profil fotoğrafı seçin")),
          );
          return;
        }
        _registerUser();
      }
    }
  }

  Widget _buildTextField(
      String label,
      Function(String?) onSaved, {
        TextInputType keyboardType = TextInputType.text,
        bool obscure = false,
        IconData? icon,
        double iconSize = 20, // 🔥 ikon boyutu kontrolü
        List<TextInputFormatter>? inputFormatters,
        FormFieldValidator<String>? validatorOverride,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          errorStyle: const TextStyle(color: Colors.white),
          labelText: label,
          prefixIcon: icon != null
              ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, color: Colors.white, size: iconSize),
          )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validatorOverride ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Lütfen $label girin';
          }

          if (label == "E-posta" &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Lütfen geçerli bir e-posta girin';
          }

          if (label == "TC Kimlik No") {
            if (value.length != 11 || !RegExp(r'^[1-9][0-9]{10}$').hasMatch(value)) {
              return 'TC Kimlik No 11 haneli olmalı';
            }
            List<int> digits = value.split('').map(int.parse).toList();
            int sumOdd = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
            int sumEven = digits[1] + digits[3] + digits[5] + digits[7];
            int digit10 = ((sumOdd * 7) - sumEven) % 10;
            int digit11 = (digits.sublist(0, 10).reduce((a, b) => a + b)) % 10;
            if (digits[9] != digit10 || digits[10] != digit11) {
              return 'Geçerli bir TC Kimlik No girin';
            }
          }

          if (label == "Doğum Tarihi" && (value.length != 4 || int.tryParse(value) == null)) {
            return 'Geçerli bir doğum tarihi girin';
          }

          if (label == "Telefon Numarası" && !RegExp(r'^05[0-9]{9}$').hasMatch(value)) {
            return 'Geçerli bir telefon numarası girin (05XXXXXXXXX)';
          }

          if (label == "Şifre" && value.length < 6) {
            return 'Şifre en az 6 karakter olmalı';
          }

          return null;
        },
        onSaved: onSaved,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut);
                  setState(() => _currentPage--);
                },
              ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7823B1), Color(0xFFB3C7EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // 1. Sayfa
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader("Adım 1"),
                        const SizedBox(height: 30),
                        _buildTextField("Ad", (val) => _firstName = val, icon: FontAwesomeIcons.user),
                        _buildTextField("Soyad", (val) => _lastName = val, icon: FontAwesomeIcons.userTie),
                        _buildTextField("E-posta", (val) => _email = val, icon: FontAwesomeIcons.envelope, keyboardType: TextInputType.emailAddress),
                        _buildTextField("TC Kimlik No", (val) => _tc = val, icon: FontAwesomeIcons.idCard, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(11)]),
                        _buildBirthYearPicker(icon: FontAwesomeIcons.calendar),
                        _buildTextField("Meslek", (val) => _institution = val, icon: FontAwesomeIcons.briefcase,
                        ),
                        const SizedBox(height: 20),
                        _buildButton("Devam Et", _nextPage),
                        const SizedBox(height: 12),
                        const Text(
                          "DoldurKabı, hayvanseverler için güvenli ve topluluğa dayalı bir platformdur. Bilgileriniz KVKK kapsamında korunur ve asla üçüncü kişilerle paylaşılmaz. ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Sayfa
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      _buildHeader("Adım 2"),
                      const SizedBox(height: 30),
                      _buildTextField(
                        "Telefon Numarası",
                            (val) => _phone = val,
                        icon: Icons.phone,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                      _buildPasswordField("Şifre", (val) => _password = val, _obscurePassword, () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      }),


                      _buildTextField(
                        "Şifre Tekrar",
                            (val) => _confirmPassword = val,
                        icon: Icons.lock_outline,
                        obscure: true,
                        inputFormatters: null,
                        keyboardType: TextInputType.text,
                        validatorOverride: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Lütfen Şifre Tekrar girin';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),
                      _buildButton("Devam Et", _nextPage),
                    ],
                  ),

                  // 3. Sayfa – Profil Fotoğrafı
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      _buildHeader("Adım 3"),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () => _pickImage(),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : null,
                                child: _selectedImage == null
                                    ? const Icon(Icons.add_a_photo,
                                        size: 36, color: Colors.white)
                                    : null,
                              ),
                              if (_selectedImage != null)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildButton("Kaydol", _nextPage),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio3x2,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = "${dir.path}/compressed.jpg";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _registerUser() async {
    setState(() => _isLoading = true); // 🔄 Başlangıçta aç

    try {
      // ✅ Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );

      User? user = userCredential.user;

      if (user != null) {
        // ✅ Profil fotoğrafı yükle
        File? compressed = await _compressImage(_selectedImage!);
        if (compressed == null) throw Exception("Resim sıkıştırılamadı");

        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures/${user.uid}.jpg");

        final bytes = await compressed.readAsBytes();
        await ref.putData(bytes);
        final imageUrl = await ref.getDownloadURL();

        // ✅ Firestore'a kaydet
        await _firestore.collection("users").doc(user.uid).set({
          "firstName": _firstName,
          "lastName": _lastName,
          "email": _email,
          "tc": _tc,
          "birthYear": _birthYear,
          "institution": _institution,
          "phone": _phone,
          "profileUrl": imageUrl,
          "createdAt": Timestamp.now(),
          "mamaDoldurmaSayisi": 0,
          "beslemeNoktasiSayisi": 0,
          "gonderiSayisi": 0,
          "hayvanEviSayisi": 0,
          "points": 0,
        });

        // ✅ Auth profiline ad ve resim ata
        await user.updateDisplayName("$_firstName $_lastName");
        await user.updatePhotoURL(imageUrl);
        await user.reload();

        // ✅ Başarı mesajı
        if (mounted) {
          showCustomSnackbar(context, "Kayıt başarılı! Lütfen giriş yapınız.");

          // Kullanıcıyı çıkış yap ve login ekranına yönlendir
          await FirebaseAuth.instance.signOut();

          await Future.delayed(const Duration(seconds: 3));

          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }



      }
    } catch (e) {
      print("❌ HATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    }
    finally {
      if (mounted) setState(() => _isLoading = false); // ✅ İşlem sonunda kapat
    }
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  void showCustomSnackbar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 60,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSnackBar(message: message),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }


  Widget _buildBirthYearPicker({IconData icon = Icons.calendar_today}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          DateTime? selected = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year - 20),
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year),
            helpText: "Doğum Tarihinizi Seçin",
          );
          if (selected != null) {
            setState(() {
              _birthYearController.text = DateFormat('dd.MM.yyyy').format(selected);
              _birthYear = DateFormat('dd.MM.yyyy').format(selected);
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _birthYearController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Doğum Tarihi",
              prefixIcon: Icon(icon, color: Colors.white), // buraya parametre geldi
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen doğum tarihinizi seçin';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }


  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed, // Loading iken buton pasif
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      )
          : Text(text, style: const TextStyle(fontSize: 18)),
    );
  }
}

Widget _buildPasswordField(String label, Function(String?) onSaved, bool obscure, VoidCallback toggle) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: TextFormField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
          onPressed: toggle,
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.white),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Lütfen $label girin';
        if (label == "Şifre" && value.length < 6) return 'Şifre en az 6 karakter olmalı';
        return null;
      },
      onSaved: onSaved,
    ),
  );
}

class AnimatedSnackBar extends StatefulWidget {
  final String message;

  const AnimatedSnackBar({Key? key, required this.message}) : super(key: key);

  @override
  State<AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

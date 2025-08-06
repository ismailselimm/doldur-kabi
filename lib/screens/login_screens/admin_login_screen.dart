import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doldur_kabi/screens/admin_screens/admin_dashboard_screen.dart';


class AdminLoginScreen extends StatelessWidget {
  AdminLoginScreen({super.key});

  final TextEditingController _adminCodeController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  Future<void> _handleAdminLogin(BuildContext context) async {
    final code = _adminCodeController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (code == "admin@doldurkabi.com" && password == "admin123") {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: code,
          password: password,
        );

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Hoş Geldin Admin 👑"),
            content: const Text("Yönetim paneline başarıyla giriş yaptınız."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Alert'ı kapat

                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      );
                    }
                  });
                },
                child: const Text("Tamam"),
              ),
            ],
          ),
        );
      } catch (e) {
        debugPrint("❌ Admin Girişi Hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firebase girişi başarısız.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hatalı kod veya şifre")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 📸 Arka Plan Resmi
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash2.png",
              fit: BoxFit.cover,
            ),
          ),
          // 💨 Blur Efekti
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          // 🎯 İçerik
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Admin Girişi',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    controller: _adminCodeController,
                    labelText: 'Admin Kodu',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: _obscurePassword,
                    builder: (context, obscure, _) {
                      return _buildTextField(
                        controller: _adminPasswordController,
                        labelText: 'Şifre',
                        icon: Icons.lock_outline,
                        obscureText: obscure,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            _obscurePassword.value = !obscure;
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleAdminLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.95),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black38,
                      ),
                      child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

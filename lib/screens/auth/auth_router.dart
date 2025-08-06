import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doldur_kabi/screens/home_screens/main_home_page.dart';
import 'package:doldur_kabi/services/auth_service.dart';

class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const HomePage(); // Giriş yapılmamışsa da home açılıyor
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

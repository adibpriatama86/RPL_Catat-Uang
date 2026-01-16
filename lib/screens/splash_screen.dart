import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prototype_catat_uang/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. SETUP ANIMASI "BERNAPAS" (Scale Up & Down)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Kecepatan napas
    )..repeat(reverse: true); // Ulangi bolak-balik (Gede-Kecil-Gede)

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 2. PINDAH HALAMAN SETELAH 3 DETIK
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi Dark Mode
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO DENGAN ANIMASI SCALE
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/logo_transparent.png', // PASTIIN NAMA FILE INI BENER
                width: 180,
                height: 180,
              ),
            ),
            const SizedBox(height: 30),
            
            // JUDUL APP
            Text(
              "Catat Uang",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            
            // TAGLINE
            // Text(
            //   "Anti Boncos Club 💸", // Tagline Gen Z banget wkwk
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: isDark ? Colors.grey : Colors.grey[600],
            //     fontFamily: 'Poppins',
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
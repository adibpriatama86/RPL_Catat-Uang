import 'package:flutter/material.dart';
import 'package:prototype_catat_uang/screens/main_screen.dart'; // Sesuaikan nama package lo

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catat Duit',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFFF6B6B),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.light,
          primary: const Color(0xFFFF6B6B),
          secondary: Colors.teal,
          surface: Colors.white,
        ),
        
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),

        // === INI CUMA SETTING STYLE GLOBAL ===
        // Bukan tempat naruh Widget Navbar!
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white, 
          surfaceTintColor: Colors.white,
          indicatorColor: const Color(0xFFFF6B6B).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          iconTheme: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.selected)) {
               return const IconThemeData(color: Color(0xFFFF6B6B));
             }
             return const IconThemeData(color: Colors.grey);
          }),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50], 
          labelStyle: const TextStyle(color: Colors.black54),
          hintStyle: const TextStyle(color: Colors.black38),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
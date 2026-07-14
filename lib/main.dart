// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';
import 'customer/contentbuttom/navigation_button.dart';
import 'customer/content/history_rating.dart';
import 'teknisi/contenbuttom/navigation_button_teknisi.dart'; // ← tambah ini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kominfo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        textTheme: GoogleFonts.notoSansTextTheme(),
      ),
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/login':
            page = const LoginScreen();
            break;
          case '/home':
            page = const MainScaffold();
            break;
          case '/history_rating':
            page = const HistoryRating();
            break;

          // ─── Customer ──────────────────────────────
          case '/customer/dashboard':
            page = const MainScaffold(initialIndex: 0);
            break;

          // ─── Teknisi ───────────────────────────────
          case '/teknisi/dashboard':
            page = const MainScaffoldTeknisi(initialIndex: 0);
            break;

          default:
            page = const LoginScreen();
        }
        return AppNavigator.slideRoute(page);
      },
    );
  }
}

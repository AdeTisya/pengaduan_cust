import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'contentbuttom/navigation_button.dart';
import 'content/history_rating.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
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
          default:
            page = const LoginScreen();
        }
        return AppNavigator.slideRoute(page);
      },
    );
  }
}

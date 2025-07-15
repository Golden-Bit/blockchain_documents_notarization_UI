import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/user_manager/pages/login_page_1.dart';
import '/user_manager/pages/registration_page_1.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(),
  
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockchain-Notarization',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          bodyMedium: GoogleFonts.inter(fontSize: 14),
          
        ),
                // ───────────– GLOBAL DIALOG STYLES ───────────–
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        // ────────────────────────────────────────────────
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
      },
    );
  }
}
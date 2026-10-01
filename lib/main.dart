import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLocalLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final bool isFirebaseLoggedIn = FirebaseAuth.instance.currentUser != null;
  final bool isLoggedIn = isLocalLoggedIn || isFirebaseLoggedIn;

  runApp(NirbhoyApp(isLoggedIn: isLoggedIn));
}

class NirbhoyApp extends StatelessWidget {
  final bool isLoggedIn;
  const NirbhoyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NIRVHOY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}


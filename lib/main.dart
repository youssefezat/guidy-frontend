import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

import 'screens/SignInScreen.dart';
import 'screens/SignUpScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/ReportScreen.dart';

void main() async {
  // 1. This MUST be here before Firebase initializes
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. This wakes up Firebase
  await Firebase.initializeApp();

  runApp(const GuidyApp());
}

const Color kPrimaryColor = Color(0xFF6DA4C2);
const Color kAccentColor = Color(0xFFD4A373);
const Color kBackgroundColor = Color(0xFFF0F4F8);

class GuidyApp extends StatelessWidget {
  const GuidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guidy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      // We removed initialRoute and replaced it with the AuthGate
      home: const AuthGate(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/report': (context) => const ReportScreen(),
      },
    );
  }
}

// --- THE AUTH GATE ---
// This listens to Firebase and decides which screen to show on boot.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading circle while checking Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
        }
        
        // If the user's data exists, they are logged in. Send to Home!
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // If not logged in, send to Sign In.
        return const SignInScreen();
      },
    );
  }
}
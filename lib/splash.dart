import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/home.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkFirstTimeUser();
  }

  // Function to check if the user has already seen onboarding
  Future<void> checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('onboardingCompleted') ?? false;

    // Delay for splash screen
    await Future.delayed(Duration(seconds: 2));

    // Navigate to Onboarding or Home based on user status
    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingPage1()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return bannerpage();
  }

  Scaffold bannerpage() {
    return Scaffold(
      body: Stack(
      fit: StackFit.expand,
      children: [
        // Background Image (Bhagavad Gita)
        Image.asset(
        'assets/Images/Bg.png',
        fit: BoxFit.cover,
        ),
        // Overlay (dark or orange)
        Container(
        color: Colors.orange.withOpacity(0.4), // You can adjust opacity or use Colors.black.withOpacity(0.6)
        ),
        // Foreground content
        Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Large App Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
            'assets/Images/Logo_2.png',
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 40),
          // App Name
          Text(
            "Sanskrit Recitation",
            style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
              blurRadius: 8,
              color: Colors.black45,
              offset: Offset(2, 2),
              ),
            ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          // Tagline
          Text(
            "Learn. Chant. Connect.",
            style: TextStyle(
            fontSize: 22,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
            shadows: [
              Shadow(
              blurRadius: 6,
              color: Colors.black38,
              offset: Offset(1, 1),
              ),
            ],
            ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
        ),
      ],
      ),
    );
  }
}

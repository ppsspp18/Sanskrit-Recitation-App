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
    await Future.delayed(Duration(seconds: 3));

    // Navigate to Onboarding if first time, else go to Home
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
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
         child: ClipOval(
           child: Image.asset('assets/bhagavad_gita.png',
           width: 225, height: 315,
           fit: BoxFit.cover,
          )
          )
        ),
      ),
    );
  }
}

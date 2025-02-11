import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage4 extends StatefulWidget {
  const OnboardingPage4({super.key});

  @override
  State<OnboardingPage4> createState() => _OnboardingPage4State();
}

class _OnboardingPage4State extends State<OnboardingPage4> {
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                    onPressed: completeOnboarding,
                    child: Text('Lets Start',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                      ),
                    )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page4.dart';

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>
                            OnboardingPage4()
                        ),
                      );
                    },
                    child: Text('skip',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                      ),
                    )
                ),
                Text('page 3 of 4',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                TextButton(
                    onPressed: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>
                            OnboardingPage4()
                        ),
                      );
                    },
                    child: Text('next',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                      ),
                    )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
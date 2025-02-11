import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page2.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page4.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
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
                Text('page 1 of 4',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                TextButton(
                    onPressed: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>
                            OnboardingPage2()
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

import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page3.dart';
import 'package:sanskrit_racitatiion_project/onBoarding/Onboarding_page4.dart';


class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2> {
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
                      Navigator.pushReplacement(context,
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
                Text('page 2 of 4',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                TextButton(
                    onPressed: (){
                      Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context)=>
                            OnboardingPage3()
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
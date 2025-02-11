import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/home.dart';

class OnboardingPage4 extends StatefulWidget {
  const OnboardingPage4({super.key});

  @override
  State<OnboardingPage4> createState() => _OnboardingPage4State();
}

class _OnboardingPage4State extends State<OnboardingPage4> {
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
                    onPressed: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>
                            HomePage(),
                        ),
                      );
                    },
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
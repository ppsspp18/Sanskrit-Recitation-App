import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller= PageController();
  bool _isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index){
              setState(() {
                _isLastPage = index == 3;
              });
            },
          children: [
            buildPage(
              title:
            )
          ],
          )
          Positioned(
            bottom: 20,
            left: 20,
            child: _isLastPage?SizedBox()
                :TextButton(
                  onPressed: (){
                    _controller.jumpTo(3);
                  }
                  child: Text('skip'),
                  ),
           ),
        ],
      ),
    );
  }
}





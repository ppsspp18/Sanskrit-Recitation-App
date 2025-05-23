import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/splash.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  // Initialize AudioPlayer global settings
  AudioCache.instance = AudioCache(prefix: '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanskrit Recitation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,

      ),
      home: SplashPage(),

    );
  }
}



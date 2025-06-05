import 'package:flutter/material.dart';
import 'package:sanskrit_racitatiion_project/splash.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_racitatiion_project/theme/theme_provider.dart';
import 'package:sanskrit_racitatiion_project/widgets/global_audio_player.dart';
import 'package:sanskrit_racitatiion_project/audio/audio_provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:sanskrit_racitatiion_project/firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // // Initialize Firebase with error handling
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   debugPrint('Firebase initialized successfully');
  // } catch (e) {
  //   debugPrint('Failed to initialize Firebase: $e');
  //   // Continue anyway, as the app might work without Firebase
  // }

  // Initialize AudioPlayer global settings
  AudioCache.instance = AudioCache(prefix: '');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GlobalAudioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        return MaterialApp(
          title: 'Sanskrit Recitation',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: theme.color1,
            scaffoldBackgroundColor: theme.color4,
            appBarTheme: AppBarTheme(
              backgroundColor: theme.color1,
              foregroundColor: theme.color2,
            ),
          ),
          home: Stack(
            children: [
              SplashPage(),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: GlobalAudioPlayerWidget(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


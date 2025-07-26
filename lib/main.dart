import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/info_screen.dart';
import 'screens/diary_screen.dart';

void main() {
  runApp(const FaberKkuPlantApp());
}

class FaberKkuPlantApp extends StatelessWidget {
  const FaberKkuPlantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'faber_kku_plant',
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/info': (context) => const InfoScreen(),
        '/diary': (context) => const DiaryScreen(),
      },
    );
  }
}

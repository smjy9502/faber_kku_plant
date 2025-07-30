import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ locale 초기화용
import 'screens/main_screen.dart';
import 'screens/info_screen.dart';
import 'screens/diary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ 필수!
  await initializeDateFormatting('ko_KR', null); // ✅ 한국어 날짜 포맷 초기화
  runApp(const FaberKkuPlantApp());
}

class FaberKkuPlantApp extends StatelessWidget {
  const FaberKkuPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'faber_kku_plant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Pretendard',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/info': (context) => const InfoScreen(),
        '/diary': (context) => const DiaryScreen(),
      },
    );
  }
}

import 'package:faber_kku_plant/screens/error_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ locale 초기화용
import 'screens/main_screen.dart';
import 'screens/info_screen.dart';
import 'screens/diary_screen.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'firebase_options.dart';
import 'dart:html' as html;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // FirebaseOptions 명시적 전달
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
    await initializeDateFormatting('ko_KR', null);// ✅ 한국어 날짜 포맷 초기화
    runApp(const FaberKkuPlantApp());
  } catch (e) {
    print("Firebase 초기화 실패: $e");
    runApp(MaterialApp(home: ErrorScreen()));
  }
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

Future<bool> checkInitialAccess() async {
  if (foundation.kIsWeb) {
    final uri = Uri.parse(html.window.location.href);
    final hasUrlParams = uri.queryParameters.isNotEmpty;

    // 1. URL 파라미터 없으면 세션스토리지 삭제
    if (!hasUrlParams) {
      html.window.sessionStorage.remove('params');
    } else {
      // 2. URL 파라미터 있으면 세션스토리지 저장
      html.window.sessionStorage['params'] =
          uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    // 3. 세션스토리지 체크
    final storedParams = html.window.sessionStorage['params'];
    if (!hasUrlParams && (storedParams == null || storedParams.isEmpty)) {
      return false; // ErrorScreen 표시
    }

    // 4. 모바일 체크 (기존 로직 유지)
    final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
    final isMobile = userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone');
    return isMobile;
  }
  return true;
}


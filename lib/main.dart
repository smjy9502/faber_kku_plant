import 'dart:html' as html;
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
    await initializeDateFormatting('ko_KR', null);
    runApp(const FaberKkuPlantGateApp());
  } catch (e) {
    print("Firebase 초기화 실패: $e");
    runApp(const MaterialApp(home: ErrorScreen(), debugShowCheckedModeBanner: false));
  }
}

class FaberKkuPlantGateApp extends StatefulWidget {
  const FaberKkuPlantGateApp({super.key});

  @override
  State<FaberKkuPlantGateApp> createState() => _FaberKkuPlantGateAppState();
}

class _FaberKkuPlantGateAppState extends State<FaberKkuPlantGateApp> {
  bool? _allowAccess;
  bool _isMobile = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkAccessLogic();
  }

  void _checkAccessLogic() {
    bool allowed = false;
    bool mobile = false;
    String? userId;

    if (foundation.kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      mobile = userAgent.contains('mobile') ||
          userAgent.contains('android') ||
          userAgent.contains('iphone');

      if (!mobile) {
        allowed = false;
        html.window.sessionStorage.remove('entry_visited');
      } else {
        final storedOnce = html.window.sessionStorage['entry_visited'];
        if (uri.queryParameters.length == 1 &&
            uri.queryParameters.containsKey('no') &&
            int.tryParse(uri.queryParameters['no'] ?? '') != null &&
            (storedOnce == null || storedOnce != 'true')) {
          html.window.sessionStorage['entry_visited'] = 'true';
          userId = uri.queryParameters['no']!;
          final cleanUrl = uri.removeFragment().replace(queryParameters: {}).toString();
          html.window.history.replaceState(null, '', cleanUrl);
          allowed = true;
        } else {
          allowed = false;
        }
      }
    } else {
      allowed = false;
    }

    setState(() {
      _allowAccess = allowed;
      _isMobile = mobile;
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allowAccess == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    if (_allowAccess == true && _isMobile && _userId != null) {
      return MaterialApp(
        title: 'faber_kku_plant',
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Pretendard',
        ),
        debugShowCheckedModeBanner: false,
        home: MainScreen(userId: _userId!), // userId 전달
      );
    }
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ErrorScreen(),
    );
  }
}

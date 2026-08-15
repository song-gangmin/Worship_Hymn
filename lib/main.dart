import 'package:flutter/material.dart';
import 'screens/splash/section0_screen.dart';
import 'screens/login/section1_screen.dart';
import 'screens/main/main_screen.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // FlutterFire CLI로 자동 생성된 파일

import 'package:provider/provider.dart';
import 'providers/font_provider.dart';
import 'providers/display_provider.dart';
import 'providers/color_provider.dart';

import 'utils/version_checker.dart';
import 'screens/splash/update_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 중복 초기화 완벽 방지
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized');
    } else {
      Firebase.app();
      debugPrint('⚡ Firebase already initialized — using existing instance');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('⚠️ Firebase already initialized — continuing...');
    } else {
      debugPrint('❌ Firebase init error: ${e.message}');
      rethrow;
    }
  }
  KakaoSdk.init(nativeAppKey: '964ca6284360a7db3f8400c26a5d4be9');


  // ✅ Firestore 캐시 설정 (초기화 후)
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => DisplayProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ColorProvider, DisplayProvider>(
      builder: (context, colorProvider, displayProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: displayProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Pretendard',
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            primaryColor: colorProvider.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorProvider.primaryColor,
              primary: colorProvider.primaryColor,
              brightness: Brightness.light,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF007AFF), // Apple Blue
              selectionColor: Color(0x4D007AFF), // Apple Blue (30% opacity)
              selectionHandleColor: Color(0xFF007AFF),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Pretendard',
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: colorProvider.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorProvider.primaryColor,
              primary: colorProvider.primaryColor,
              brightness: Brightness.dark,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF0A84FF), // Apple Dark Mode Blue
              selectionColor: Color(0x4D0A84FF),
              selectionHandleColor: Color(0xFF0A84FF),
            ),
            useMaterial3: true,
          ),
          home: const AppStartupWrapper(),
        );
      },
    );
  }
}

class AppStartupWrapper extends StatefulWidget {
  const AppStartupWrapper({super.key});

  @override
  State<AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<AppStartupWrapper> {
  bool _isInitDone = false;
  UpdateInfo? _updateInfo;
  bool _skipUpdate = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1.5초 지연과 버전 체크를 동시에 수행
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      VersionChecker.checkUpdate(),
    ]);

    if (mounted) {
      setState(() {
        _updateInfo = results[1] as UpdateInfo;
        _isInitDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitDone) {
      return const Section0Screen(); // Splash 화면
    }

    // 업데이트 체크 로직
    if (_updateInfo != null && _updateInfo!.type != UpdateType.none && !_skipUpdate) {
      return UpdateScreen(
        updateInfo: _updateInfo!,
        onSkip: () {
          setState(() {
            _skipUpdate = true;
          });
        },
      );
    }

    // 기존 인증 로직
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        // 디버깅용 로그
        if (snap.connectionState == ConnectionState.active) {
          final u = snap.data;
          debugPrint(">>> main.dart authState: ${u == null ? '로그아웃' : (u.isAnonymous ? '익명(${u.uid})' : '소셜(${u.uid})')}");
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Section0Screen();
        }

        final user = snap.data;

        // 유저가 없으면 로그인 화면 유지
        if (user == null) {
          return const Section1Screen();
        }

        return MainScreen(key: ValueKey(user.uid));
      },
    );
  }
}

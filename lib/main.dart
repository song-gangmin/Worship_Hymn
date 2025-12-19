import 'package:flutter/material.dart';
import 'screens/splash/section0_screen.dart';
import 'screens/login/section1_screen.dart';
import 'screens/main/main_screen.dart';
import 'constants/colors.dart';
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
            useMaterial3: true,
          ),
          home: FutureBuilder(
            // section1_screen 최소 1.5초 기다리기
            future: Future.delayed(const Duration(milliseconds: 1500)),
            builder: (context, snapDelay) {
              if (snapDelay.connectionState != ConnectionState.done) {
                return const Section0Screen();
              }

              // 1초 후 FirebaseAuth 상태 체크
              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (ctx, snap) {

                  // 🔴 디버깅용 로그 추가
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

                  print(">>> 유저 확인됨! MainScreen으로 이동 (UID: ${user.uid})");
                  return MainScreen(key: ValueKey(user.uid));
                },
              );
            },
          ),
        );
      },
    );
  }
}

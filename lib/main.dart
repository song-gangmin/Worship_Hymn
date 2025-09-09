import 'package:flutter/material.dart';
import 'section0_screen.dart';
import 'section1_screen.dart';
import 'main_screen.dart';
import 'constants/colors.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart'; // ✅ KakaoSdk 여기 있음

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  KakaoSdk.init(nativeAppKey: '964ca6284360a7db3f8400c26a5d4be9'); // kakao 접두사 없이 “키만”
  await GoogleSignIn.instance.initialize(
    clientId: '800123758723-vsj9al4l2llgpg86kmd9uu4932ktuqd4.apps.googleusercontent.com'
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snap) {
          // 스플래시 느낌으로 Section0 먼저 보여주고, 상태 결정되면 라우팅
          if (snap.connectionState == ConnectionState.waiting) {
            return const Section0Screen(); // 로고/로딩
          }
          if (snap.data != null) {
            final u = snap.data!;
            return MainScreen(
              name: u.displayName ?? '이름 없음',
              email: u.email ?? '이메일 없음',
            );
          }
          return const Section1Screen(); // 처음 사용자(로그인 화면)
        },
      ),
      title: '예배찬송가',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Pretendard', // 나중에 폰트 추가 시
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF673E38)),
        useMaterial3: true,
      ),
    );
  }
}

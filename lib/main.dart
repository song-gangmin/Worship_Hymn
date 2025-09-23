import 'package:flutter/material.dart';
import 'section0_screen.dart';
import 'section1_screen.dart';
import 'main_screen.dart';
import 'constants/colors.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  KakaoSdk.init(nativeAppKey: '964ca6284360a7db3f8400c26a5d4be9');
  await GoogleSignIn.instance.initialize(
      clientId: '800123758723-vsj9al4l2llgpg86kmd9uu4932ktuqd4.apps.googleusercontent.com'
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        // 여기서 바로 MaterialApp을 갈아치움
        if (snap.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Section0Screen(),
            debugShowCheckedModeBanner: false,
          );
        }
        if (snap.data != null) {
          final u = snap.data!;
          return MaterialApp(
            home: MainScreen(
              name: u.displayName ?? '이름 없음',
              email: u.email ?? '이메일 없음',
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        return const MaterialApp(
          home: Section1Screen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

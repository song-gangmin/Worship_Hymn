import 'package:flutter/material.dart';
import 'section0_screen.dart';
import 'section1_screen.dart';
import 'main_screen.dart';
import 'constants/colors.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  KakaoSdk.init(nativeAppKey: '964ca6284360a7db3f8400c26a5d4be9');
  await GoogleSignIn.instance.initialize(
      clientId: '800123758723-vsj9al4l2llgpg86kmd9uu4932ktuqd4.apps.googleusercontent.com'
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Section0Screen(); // 로딩
          }
          final user = snap.data;
          if (user == null) {
            return const Section1Screen(); // 로그인 화면
          }
          // ✅ Firestore users/{uid} 문서를 구독
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snap2) {
              if (!snap2.hasData) {
                return const Section0Screen(); // 로딩 표시
              }
              final data = snap2.data?.data() ?? {};
              return MainScreen(
                name: data['name'] ?? user.displayName ?? '',   // ← 기본값 제거
                email: data['email'] ?? user.email ?? '',       // ← 기본값 제거
              );            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'section0_screen.dart';
import 'section1_screen.dart';
import 'main_screen.dart';
import 'constants/colors.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'dart:async';


import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // FlutterFire CLI로 자동 생성된 파일



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

  // ✅ Firestore 캐시 설정 (초기화 후)
  FirebaseFirestore.instance.settings =
  const Settings(persistenceEnabled: true);

  // ✅ 테스트용 익명 로그인 (권한 문제 방지)
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('👤 Signed in anonymously for test');
  }

  // ✅ Firestore 연결 테스트
  await testFirestoreConnection();

  runApp(const MyApp());
}

Future<void> testFirestoreConnection() async {
  debugPrint('🔥 testFirestoreConnection() start');
  try {
    final ref = await FirebaseFirestore.instance
        .collection('test_connection')
        .add({
      'platform': 'ios',
      'tsClient': Timestamp.now(),
      'tsServer': FieldValue.serverTimestamp(),
    })
        .timeout(const Duration(seconds: 5));

    final snap = await ref
        .get(const GetOptions(source: Source.server));

    debugPrint('✅ Firestore ok | doc=${ref.id} | serverTs=${snap.data()?['tsServer']}');
  } on FirebaseException catch (e, st) {
    debugPrint('❌ Firestore FirebaseException: ${e.code} - ${e.message}');
    debugPrint(st.toString());
  } on TimeoutException catch (_) {
    debugPrint('⏱️ Firestore request timed out');
  } catch (e, st) {
    debugPrint('❌ Firestore unknown error: $e');
    debugPrint(st.toString());
  } finally {
    debugPrint('🏁 testFirestoreConnection() end');
  }
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

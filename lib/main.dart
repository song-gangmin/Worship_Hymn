import 'package:flutter/material.dart';
import 'section0_screen.dart';
import 'constants/colors.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';


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
      home: const Section0Screen(), // 처음 화면 설정
    );
  }
}

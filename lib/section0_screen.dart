import 'package:flutter/material.dart';
import 'section1_screen.dart'; // 로그인 화면

class Section0Screen extends StatefulWidget {
  const Section0Screen({super.key});

  @override
  State<Section0Screen> createState() => _Section0ScreenState();
}

class _Section0ScreenState extends State<Section0Screen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF673E38),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 (svg나 png 기반 이미지)
            Image.asset(
              'assets/icon/app_icon.png',
              width: 240,
              height: 240,
            ),
          ],
        ),
      ),
    );
  }
}
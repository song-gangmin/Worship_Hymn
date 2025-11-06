import 'package:flutter/material.dart';
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
            Image.asset('assets/icon/app_icon.png', width: 240, height: 240,),
          ],
        ),
      ),
    );
  }
}
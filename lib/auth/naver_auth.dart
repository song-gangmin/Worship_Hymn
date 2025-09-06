import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NaverAuth {
  static const String clientId = "uCalTrNx7kUnkKbdsV7L";
  static const String clientSecret = "AdDC6nLXyg";
  static const String redirectUri = "myapp://login/callback"; // 앱 스킴

  /// 네이버 로그인 → Firestore에 사용자 저장
  static Future<Map<String, String>?> signIn() async {
    try {
      // ✅ 1. 네이버 로그인 URL
      final authUrl =
          "https://nid.naver.com/oauth2.0/authorize?response_type=code"
          "&client_id=$clientId"
          "&redirect_uri=$redirectUri"
          "&state=RANDOM_STATE";

      // ✅ 2. 브라우저에서 로그인 시작
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: "myapp",
      );

      // ✅ 3. code 추출
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      // ✅ 4. 토큰 발급
      final tokenRes = await http.post(
        Uri.parse("https://nid.naver.com/oauth2.0/token"),
        body: {
          "grant_type": "authorization_code",
          "client_id": clientId,
          "client_secret": clientSecret,
          "code": code,
          "state": "RANDOM_STATE",
        },
      );

      final tokenData = jsonDecode(tokenRes.body);
      final accessToken = tokenData["access_token"];
      if (accessToken == null) return null;

      // ✅ 5. 사용자 정보 요청
      final userRes = await http.get(
        Uri.parse("https://openapi.naver.com/v1/nid/me"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      final userData = jsonDecode(userRes.body);
      if (userData["response"] == null) return null;

      final profile = userData["response"];
      final name = profile["name"] ?? profile["nickname"] ?? "이름 없음";
      final email = profile["email"] ?? "이메일 정보 없음";

      // ✅ 6. Firestore에 저장
      final userId = "naver_${profile["id"]}";
      await FirebaseFirestore.instance.collection("users").doc(userId).set({
        "name": name,
        "email": email,
        "provider": "naver",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {"name": name, "email": email};
    } catch (e) {
      print("네이버 로그인 실패: $e");
      return null;
    }
  }
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuth {
  /// 로그인 (카카오톡 → 실패 시 카카오계정 폴백)
  static Future<User?> signIn() async {
    try {
      OAuthToken token;

      final talkInstalled = await isKakaoTalkInstalled();

      if (talkInstalled) {
        try {
          // 1) 카카오톡 우선
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          // 사용자가 명시적으로 취소한 경우는 그대로 종료
          if (_isUserCanceled(e)) return null;

          // 기타 오류는 2) 카카오계정으로 폴백
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 시뮬레이터(iOS)나 Talk 미설치 기기 → 바로 계정 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 로그인 성공 → 프로필 가져오기
      final user = await UserApi.instance.me();
      // 필요하면 token.accessToken / refreshToken 서버 전달
      return user;
    } catch (e) {
      // 여기서 스낵바/로그 등 처리
      rethrow;
    }
  }

  /// 로그아웃 (서버 세션 유지, 기기 토큰만 만료)
  static Future<void> signOut() async {
    await UserApi.instance.logout();
  }

  /// 연결 끊기(회원탈퇴, 카카오와 앱 연동 해제)
  static Future<void> unlink() async {
    await UserApi.instance.unlink();
  }

  /// 사용자가 로그인 플로우를 취소했는지 휴리스틱 판별
  static bool _isUserCanceled(Object e) {
    // 플러그인/플랫폼마다 메시지가 조금 다를 수 있어 넓게 체크
    final msg = e.toString().toLowerCase();
    return msg.contains('canceled') ||
        msg.contains('cancelled') ||
        msg.contains('user canceled') ||
        (e is PlatformException && e.code.toLowerCase().contains('canceled'));
  }
}

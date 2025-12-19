import 'package:firebase_auth/firebase_auth.dart';
import 'user_data_migrator.dart';

class FirebaseAuthBridge {
  FirebaseAuthBridge._();
  static final FirebaseAuthBridge instance = FirebaseAuthBridge._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserDataMigrator _migrator = UserDataMigrator();

  /// 👉 카카오/네이버/구글에서 만든 AuthCredential을 여기로 넘겨주면 됨
  Future<User?> signInWithCredential(AuthCredential credential) async {
    final current = _auth.currentUser;

    // 1) 이론상 거의 안 들어오는 케이스(익명로그인 실패 등) → 그냥 로그인
    if (current == null) {
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    }

    // 2) 지금 익명 계정이면 → linkWithCredential 시도
    if (current.isAnonymous) {
      final anonUid = current.uid;

      try {
        final linkResult = await current.linkWithCredential(credential);
        // uid 그대로, 데이터 그대로
        return linkResult.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // ❗ 이미 이 소셜 계정으로 가입된 계정이 있을 때
          // 🔥 1) 현재 유저(익명) 데이터 미리 수집
          final Map<String, dynamic> collectedData = await _migrator.collectData(anonUid);

          // 2) 소셜 계정으로 로그인 (세션 전환)
          final signInResult = await _auth.signInWithCredential(credential);
          final newUser = signInResult.user;

          if (newUser != null) {
            // 🔥 3) 새 계정으로 마이그레이션 적용
            await _migrator.applyMigration(newUser.uid, collectedData);
          }
          return newUser;
        } else {
          rethrow;
        }
      }
    }

    // 3) 이미 정식 계정으로 로그인된 상태에서 다시 로그인 시도
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }
}

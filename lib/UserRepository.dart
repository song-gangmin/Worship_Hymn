import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/resualt_auth.dart';

class UserRepository {
  final _col = FirebaseFirestore.instance.collection('users');

  /// 소셜 로그인 결과(AuthUser) 기반으로 upsert
  Future<void> upsertUser(AuthUser user) async {
    print(">>> Firestore upsert 시작: ${user.uid}, ${user.name}, ${user.email}");

    final doc = _col.doc(user.uid);
    print("🔥 doc 성공");

    try {
      await doc.set({
        'uid': user.uid,
        'provider': user.provider.name,
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("🔥 Firestore set() 호출 끝남");

      print("✅ Firestore 저장 성공: ${user.uid}");

      final snap = await doc.get();
      print("📄 Firestore 문서 내용: ${snap.data()}");
    } catch (e, st) {
      print("❌ Firestore 저장 실패: $e");
      print("🔍 StackTrace: $st");
      rethrow; // 에러를 위로 다시 던져서 더 자세히 보자
    }
  }
}
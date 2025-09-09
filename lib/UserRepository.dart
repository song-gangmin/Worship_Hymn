import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/resualt_auth.dart'; // AuthUser, AuthProvider

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> upsertUser(AuthUser u) async {
    final doc = _db.collection('users').doc(u.uid);

    // 새 문서면 createdAt 넣고, 매 로그인마다 lastLoginAt/updatedAt 갱신
    await doc.set({
      'uid': u.uid,
      'provider': u.provider.name,   // e.g. 'google' | 'naver' | 'kakao' | 'guest'
      'name': u.name,
      'email': u.email,
      'photoUrl': u.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // merge:true라 최초에만 실제로 기록됨
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }
}

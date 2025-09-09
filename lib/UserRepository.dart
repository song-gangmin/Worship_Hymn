import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/resualt_auth.dart';

class UserRepository {
  final _col = FirebaseFirestore.instance.collection('users');

  /// 소셜 로그인 결과(AuthUser) 기반으로 upsert
  Future<void> upsertUser(AuthUser user) async {
    final doc = _col.doc(user.uid);
    await doc.set({
      'uid': user.uid,
      'provider': user.provider.name,
      'name': user.name,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

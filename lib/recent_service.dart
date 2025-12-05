import 'package:cloud_firestore/cloud_firestore.dart';

class RecentService {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RecentService({required this.uid});

  CollectionReference<Map<String, dynamic>> get _recentCol =>
      _db.collection('users').doc(uid).collection('recent_hymns');

  /// 🔥 최근 본 찬송 저장 (중복이면 최신 viewedAt 으로만 갱신)
  Future<void> saveRecentHymn({
    required int hymnNumber,
    required String title,
  }) async {
    await _recentCol.doc(hymnNumber.toString()).set({
      'number': hymnNumber,
      'title': title,
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔍 최근 본 찬송 3개
  Stream<List<Map<String, dynamic>>> getRecent3() {
    return _recentCol
        .orderBy('viewedAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  /// 🔍 전체 “최근 본 찬송 목록”
  Stream<List<Map<String, dynamic>>> getAllRecent() {
    return _recentCol
        .orderBy('viewedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }
}

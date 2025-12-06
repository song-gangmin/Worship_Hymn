import 'package:cloud_firestore/cloud_firestore.dart';

class RecentService {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RecentService({required this.uid});

  /// 🔥 컬렉션 통일: recent_views
  CollectionReference<Map<String, dynamic>> get _recentCol =>
      _db.collection('users').doc(uid).collection('recent_views');

  /// 🔥 최근 본 찬송 저장 (동일 번호면 viewedAt 갱신)
  Future<void> saveRecentHymn({
    required int hymnNumber,
    required String title,
  }) async {
    await _recentCol.doc(hymnNumber.toString()).set(
      {
        'number': hymnNumber,
        'title': title,
        'viewedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 🔍 홈 화면: 최근 3개
  Stream<List<Map<String, dynamic>>> getRecent3() {
    return _recentCol
        .orderBy('viewedAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  /// 🔍 최근 7일 이내 전체 기록
  Stream<List<Map<String, dynamic>>> getRecentWithin7Days() {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    return _recentCol
        .orderBy('viewedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .where((doc) {
        final ts = doc['viewedAt'];
        if (ts == null) return false;
        final dt = (ts as Timestamp).toDate();
        return dt.isAfter(oneWeekAgo);
      })
          .map((doc) => doc.data())
          .toList();
    });
  }
}

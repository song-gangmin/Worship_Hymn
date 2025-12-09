import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 글로벌 조회수 +1
  Future<void> addView({
    required int hymnNumber,
    required String title,
  }) async {
    final doc = _db
        .collection('global_stats')
        .doc('hymns')
        .collection('items')
        .doc(hymnNumber.toString());

    await doc.set({
      'number': hymnNumber,
      'title': title,
      'weeklyCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔍 이번 주 Top 3 (7일 기준)
  Stream<List<Map<String, dynamic>>> getWeeklyTop3() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return _db
        .collection('global_stats')
        .doc('hymns')
        .collection('items')
        .where('updatedAt', isGreaterThan: weekAgo)
        .orderBy('weeklyCount', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataMigrator {
  final FirebaseFirestore _db;

  UserDataMigrator({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// 1단계: 익명 유저인 상태에서 데이터를 메모리에 모두 가져오기
  Future<Map<String, dynamic>> collectData(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    
    // 유저 기본 정보
    final userSnap = await userRef.get();
    final userData = userSnap.data();

    // 플레이리스트
    final playlistsSnap = await userRef.collection('playlists').get();
    List<Map<String, dynamic>> playlists = [];
    for (var pDoc in playlistsSnap.docs) {
      final songsSnap = await pDoc.reference.collection('songs').get();
      playlists.add({
        'id': pDoc.id,
        'data': pDoc.data(),
        'songs': songsSnap.docs.map((s) => {'id': s.id, 'data': s.data()}).toList(),
      });
    }

    // 최근 본 목록
    final recentSnap = await userRef.collection('recent_views').get();
    final recent = recentSnap.docs.map((d) => {'id': d.id, 'data': d.data()}).toList();

    return {
      'userData': userData,
      'playlists': playlists,
      'recent': recent,
    };
  }

  /// 2단계: 정식 계정으로 로그인된 상태에서 데이터를 Firestore에 쓰기
  Future<void> applyMigration(String toUid, Map<String, dynamic> collectedData) async {
    final toUserRef = _db.collection('users').doc(toUid);

    // 유저 정보 merge
    final userData = collectedData['userData'];
    if (userData != null) {
      await toUserRef.set(Map<String, dynamic>.from(userData), SetOptions(merge: true));
    }

    // 플레이리스트 + 곡 복사
    final List playlists = collectedData['playlists'];
    for (var p in playlists) {
      final String playlistId = p['id'];
      final Map<String, dynamic> pData = p['data'];
      final List songs = p['songs'];

      await toUserRef.collection('playlists').doc(playlistId).set(pData, SetOptions(merge: true));
      for (var s in songs) {
        final String songId = s['id'];
        final Map<String, dynamic> sData = s['data'];
        await toUserRef.collection('playlists').doc(playlistId).collection('songs').doc(songId).set(sData, SetOptions(merge: true));
      }
    }

    // 최근 본 목록 복사
    final List recent = collectedData['recent'];
    for (var r in recent) {
      final String rId = r['id'];
      final Map<String, dynamic> rData = r['data'];
      await toUserRef.collection('recent_views').doc(rId).set(rData, SetOptions(merge: true));
    }
  }

}

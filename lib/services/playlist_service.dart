import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistService {
  final String uid;
  final _db = FirebaseFirestore.instance;

  PlaylistService({required this.uid});

  Stream<List<Map<String, dynamic>>> getPlaylists() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
    // ✅ createdAt 대신 name 정렬 (serverTimestamp null 문제 방지)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '(이름없음)',
        'count': data['songsCount'] ?? 0,
      };
    }).toList());
  }

  // ✅ 재생목록 추가
  Future<String> addPlaylist(String name) async {
    final col = _db.collection('users').doc(uid).collection('playlists');

    // 중복 방지(동명이 하나라도 있으면 막기)
    final dup = await col.where('name', isEqualTo: name).limit(1).get();
    if (dup.docs.isNotEmpty) {
      throw StateError('DUPLICATE_PLAYLIST_NAME');
    }

    final docRef = await col.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ✅ 재생목록 이름 변경
  Future<void> renamePlaylist(String id, String newName) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(id)
        .update({'name': newName});
  }

  // ✅ 재생목록 삭제
  Future<void> deletePlaylist(String id) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(id)
        .delete();
  }

  // ✅ 재생목록에 곡 추가
  Future<void> addSongToPlaylist(String playlistId, String hymnTitle) async {
    final playlistRef = _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId);

    await _db.runTransaction((txn) async {
      await playlistRef.collection('songs').add({
        'title': hymnTitle,
        'addedAt': FieldValue.serverTimestamp(),
      });
      txn.update(playlistRef, {'songsCount': FieldValue.increment(1)});
    });
  }
}

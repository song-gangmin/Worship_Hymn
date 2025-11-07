import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistService {
  final String uid;
  final _db = FirebaseFirestore.instance;

  PlaylistService({required this.uid});

  // ✅ 재생목록 스트림 가져오기
  Stream<List<Map<String, dynamic>>> getPlaylists() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
      };
    }).toList());
  }

  // ✅ 재생목록 추가
  Future<void> addPlaylist(String name) async {
    final ref = _db.collection('users').doc(uid).collection('playlists');

    // 중복 방지
    final existing = await ref.where('name', isEqualTo: name).get();
    if (existing.docs.isNotEmpty) return;

    await ref.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
}

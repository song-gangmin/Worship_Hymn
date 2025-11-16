import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistService {
  final String uid;
  final _db = FirebaseFirestore.instance;

  PlaylistService({required this.uid});

  /// 🔹 모든 재생목록 실시간 스트림
  Stream<List<Map<String, dynamic>>> getPlaylists() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
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

  /// 🔹 재생목록 추가 (문서 ID = 이름)
  Future<String> addPlaylist(String name) async {
    final col = _db.collection('users').doc(uid).collection('playlists');

    // 🔸 Firestore에서 ID로 쓸 수 없는 문자 제거
    final safeName = name.replaceAll(RegExp(r'[\/.#$[\]]'), '_');

    // 🔸 중복 방지
    final dup = await col.doc(safeName).get();
    if (dup.exists) throw StateError('DUPLICATE_PLAYLIST_NAME');

    // 🔹 문서 ID = 이름으로 생성
    await col.doc(safeName).set({
      'name': name,
      'songsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return safeName;
  }

  /// 🔹 곡 추가 (문서 ID = 찬양 제목)
  Future<void> addSongToPlaylist(String playlistName, String hymnTitle) async {
    final playlistRef = _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistName);

    // 🔸 Firestore에 안전한 ID로 변환
    final safeTitle = hymnTitle.replaceAll(RegExp(r'[\/.#$[\]]'), '_');
    final songDoc = playlistRef.collection('songs').doc(safeTitle);

    // 🔸 중복 방지
    final existing = await songDoc.get();
    if (existing.exists) {
      print('⚠️ [Firestore] Song already exists: $hymnTitle');
      return;
    }

    await _db.runTransaction((txn) async {
      await songDoc.set({
        'title': hymnTitle,
        'addedAt': FieldValue.serverTimestamp(),
      });
      txn.update(playlistRef, {'songsCount': FieldValue.increment(1)});
    });
  }

  /// 🔹 곡 삭제
  Future<void> deleteSong(String playlistName, String hymnTitle) async {
    final safeTitle = hymnTitle.replaceAll(RegExp(r'[\/.#$[\]]'), '_');
    final playlistRef = _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistName);

    await _db.runTransaction((txn) async {
      await playlistRef.collection('songs').doc(safeTitle).delete();
      txn.update(playlistRef, {'songsCount': FieldValue.increment(-1)});
    });
  }

  /// 🔹 재생목록 이름 변경 (문서 이동)
  Future<void> renamePlaylist(String oldName, String newName) async {
    final userRef = _db.collection('users').doc(uid);
    final playlists = userRef.collection('playlists');

    final oldRef = playlists.doc(oldName);
    final newRef = playlists.doc(newName);

    final oldDoc = await oldRef.get();
    if (!oldDoc.exists) {
      print('⚠️ [Firestore] Old playlist not found: $oldName');
      return;
    }

    // 🔸 새 문서 생성 (이름 변경)
    await newRef.set({
      ...oldDoc.data()!,
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔸 songs 하위 컬렉션 복사
    final songs = await oldRef.collection('songs').get();
    for (final s in songs.docs) {
      await newRef.collection('songs').doc(s.id).set(s.data());
    }

    // 🔸 이전 문서 삭제
    await oldRef.delete();
  }

  /// 🔹 재생목록 삭제 (songs 포함)
  Future<void> deletePlaylist(String name) async {
    final playlistRef =
    _db.collection('users').doc(uid).collection('playlists').doc(name);

    final songs = await playlistRef.collection('songs').get();
    for (final s in songs.docs) {
      await s.reference.delete();
    }

    await playlistRef.delete();
  }
}
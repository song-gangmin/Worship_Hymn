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
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '(이름없음)',
        'count': data['songsCount'] ?? 0,
      };
      print('📡 Listening playlists for user: $uid');
    }).toList());
  }

  Future<String> addPlaylist(String name) async {
    final col = _db.collection('users').doc(uid).collection('playlists');

    final dup = await col.where('name', isEqualTo: name).limit(1).get();
    if (dup.docs.isNotEmpty) throw StateError('DUPLICATE_PLAYLIST_NAME');

    final docRef = await col.add({
      'name': name,
      'songsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ [Firestore] Playlist created: ${docRef.id}');
    return docRef.id;
  }

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

    print('🎵 [Firestore] Song added: $hymnTitle → playlist $playlistId');
  }

  Future<void> deletePlaylist(String id) async {
    final ref = _db.collection('users').doc(uid).collection('playlists').doc(id);
    await ref.delete();
    print('🗑️ [Firestore] Playlist deleted: $id');
  }

  /// ✅ 재생목록 이름 변경
  Future<void> renamePlaylist(String id, String newName) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(id)
        .update({'name': newName});
  }
}

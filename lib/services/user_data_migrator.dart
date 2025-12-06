import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataMigrator {
  final FirebaseFirestore _db;

  UserDataMigrator({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// fromUid(익명) → toUid(정식 계정)로 데이터 복사
  Future<void> migrateAnonymousData({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid == toUid) return; // 같은 uid면 패스

    final fromUserRef = _db.collection('users').doc(fromUid);
    final toUserRef = _db.collection('users').doc(toUid);

    // 1) users/{fromUid} → users/{toUid} merge
    final fromUserSnap = await fromUserRef.get();
    if (fromUserSnap.exists) {
      await toUserRef.set(fromUserSnap.data()!, SetOptions(merge: true));
    }

    // 2) playlists + songs 복사
    await _copyPlaylists(fromUserRef, toUserRef);

    // 3) recent_views 복사
    await _copySubcollection(
      fromUserRef.collection('recent_views'),
      toUserRef.collection('recent_views'),
    );
  }

  Future<void> _copyPlaylists(
      DocumentReference fromUserRef,
      DocumentReference toUserRef,
      ) async {
    final fromPlaylists = fromUserRef.collection('playlists');
    final toPlaylists = toUserRef.collection('playlists');

    final snap = await fromPlaylists.get();
    for (final doc in snap.docs) {
      final playlistId = doc.id;
      final data = doc.data();

      await toPlaylists.doc(playlistId).set(data, SetOptions(merge: true));

      final fromSongs =
      fromPlaylists.doc(playlistId).collection('songs');
      final toSongs =
      toPlaylists.doc(playlistId).collection('songs');

      final songsSnap = await fromSongs.get();
      for (final song in songsSnap.docs) {
        await toSongs.doc(song.id).set(song.data(), SetOptions(merge: true));
      }
    }
  }

  Future<void> _copySubcollection(
      CollectionReference from,
      CollectionReference to,
      ) async {
    final snap = await from.get();
    for (final doc in snap.docs) {
      await to.doc(doc.id).set(doc.data(), SetOptions(merge: true));
    }
  }
}

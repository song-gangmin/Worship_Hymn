import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistService {
  final String uid;
  final FirebaseFirestore _db;

  static const String allPlaylistId = '전체';

  PlaylistService({required this.uid}) : _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _playlistsCol =>
      _userRef.collection('playlists');

  /// 각 유저마다 기본 즐겨찾기 "전체" 보장 (id = '전체')
  Future<void> ensureDefaultPlaylist() async {
    final defaultRef = _playlistsCol.doc(allPlaylistId);
    final snap = await defaultRef.get();

    if (!snap.exists) {
      await defaultRef.set({
        'name': allPlaylistId,
        'songsCount': 0,
        'default': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 모든 즐겨찾기 실시간 스트림
  Stream<List<Map<String, dynamic>>> getPlaylists() {
    return _playlistsCol.orderBy('name').snapshots().map(
          (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data(); // Map<String, dynamic>
          return {
            'id': doc.id,
            'name': data['name'] ?? '(이름없음)',
            'count': data['songsCount'] ?? 0,
          };
        }).toList();
      },
    );
  }

  /// 즐겨찾기 추가 (문서 ID = 이름을 안전하게 변환한 값)
  Future<String> addPlaylist(String name) async {
    final safeName = name.replaceAll(RegExp(r'[\/.#$[\]]'), '_');

    final docRef = _playlistsCol.doc(safeName);
    final exists = await docRef.get();
    if (exists.exists) {
      throw StateError('DUPLICATE_PLAYLIST_NAME');
    }

    await docRef.set({
      'name': name,
      'songsCount': 0,
      'default': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return safeName;
  }

  /// 특정 즐겨찾기에 곡 추가 + "전체" 자동 반영
  /// 같은 즐겨찾기에 동일 곡이 이미 있으면 StateError('DUPLICATE_SONG_IN_PLAYLIST') 던짐
  Future<void> addSongSmart({
    required String playlistId,
    required int hymnNumber,

    required String title,
  }) async {
    final songId = hymnNumber.toString();

    // 1) 선택한 즐겨찾기에 추가
    final playlistRef = _playlistsCol.doc(playlistId);
    final songRef = playlistRef.collection('songs').doc(songId);

    await _db.runTransaction((txn) async {
      final songSnap = await txn.get(songRef);
      if (songSnap.exists) {
        throw StateError('DUPLICATE_SONG_IN_PLAYLIST');
      }

      txn.set(songRef, {
        'number': hymnNumber,
        'title': title,
        'addedAt': FieldValue.serverTimestamp(),
        'order': DateTime.now().millisecondsSinceEpoch, // 순서 필드 추가
      });

      txn.update(
        playlistRef,
        {'songsCount': FieldValue.increment(1)},
      );
    });

    // 2) "전체" 즐겨찾기에도 자동 추가 (이미 있으면 무시)
    if (playlistId != allPlaylistId) {
      final allRef = _playlistsCol.doc(allPlaylistId);
      final allSongRef = allRef.collection('songs').doc(songId);

      await _db.runTransaction((txn) async {
        final snap = await txn.get(allSongRef);
        if (snap.exists) {
          return; // 이미 전체에 있으면 아무것도 안 함
        }

        txn.set(allSongRef, {
          'number': hymnNumber,
          'title': title,
          'addedAt': FieldValue.serverTimestamp(),
          'order': DateTime.now().millisecondsSinceEpoch, // 순서 필드 추가
        });

        txn.update(
          allRef,
          {'songsCount': FieldValue.increment(1)},
        );
      });
    }
  }

  /// 단일 즐겨찾기에서 곡 삭제 + 필요시 "전체"에서 정리
  Future<void> deleteSongFromPlaylist({
    required String playlistId,
    required int hymnNumber,
  }) async {
    final playlistRef = _playlistsCol.doc(playlistId);
    final songsCol = playlistRef.collection('songs');

    // 🔹 1) 해당 즐겨찾기에서 number로 찾아서 모두 삭제
    await _db.runTransaction((txn) async {
      final querySnap =
      await songsCol.where('number', isEqualTo: hymnNumber).get();

      if (querySnap.docs.isEmpty) return;

      for (final doc in querySnap.docs) {
        txn.delete(doc.reference);
      }

      txn.update(
        playlistRef,
        {'songsCount': FieldValue.increment(-querySnap.docs.length)},
      );
    });

    // 🔹 2) "전체" 즐겨찾기 정리
    if (playlistId != allPlaylistId) {
      await _updateAllPlaylistAfterSongChange(hymnNumber);
    }
  }

  /// 어떤 즐겨찾기에서든 곡이 추가/삭제된 뒤
  /// 그 곡이 더 이상 어떤 즐겨찾기에도 없으면 "전체"에서도 삭제
  Future<void> _updateAllPlaylistAfterSongChange(int hymnNumber) async {
    // 1) 다른 즐겨찾기에 이 곡이 아직 남아 있는지 확인
    final allPlaylistsSnap = await _playlistsCol.get();
    bool existsSomewhereElse = false;

    for (final doc in allPlaylistsSnap.docs) {
      if (doc.id == allPlaylistId) continue;

      final songsCol = doc.reference.collection('songs');
      final q = await songsCol
          .where('number', isEqualTo: hymnNumber)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        existsSomewhereElse = true;
        break;
      }
    }

    // 2) 아무 데도 없으면 "전체"에서 삭제
    if (!existsSomewhereElse) {
      final allRef = _playlistsCol.doc(allPlaylistId);
      final songsCol = allRef.collection('songs');

      await _db.runTransaction((txn) async {
        final q = await songsCol
            .where('number', isEqualTo: hymnNumber)
            .get();

        if (q.docs.isEmpty) return;

        for (final doc in q.docs) {
          txn.delete(doc.reference);
        }

        txn.update(
          allRef,
          {'songsCount': FieldValue.increment(-q.docs.length)},
        );
      });
    }
  }

  /// 즐겨찾기 삭제 (안의 곡들 + 전체에서의 정리까지)
  Future<void> deletePlaylist(String id) async {
    if (id == allPlaylistId) {
      // "전체"는 삭제 불가
      throw StateError('CANNOT_DELETE_ALL_PLAYLIST');
    }

    final playlistRef = _playlistsCol.doc(id);
    final songsSnap = await playlistRef.collection('songs').get();

    // 곡들 하나씩 삭제 (전체 즐겨찾기 정리 포함)
    for (final doc in songsSnap.docs) {
      final data = doc.data();
      final number = (data['number'] ?? 0) as int;
      await deleteSongFromPlaylist(
        playlistId: id,
        hymnNumber: number,
      );
    }
    // 마지막으로 즐겨찾기  자체 삭제
    await playlistRef.delete();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    if (id == allPlaylistId) {
      throw StateError('CANNOT_RENAME_ALL_PLAYLIST');
    }
    await _playlistsCol.doc(id).update({'name': newName});
  }
}
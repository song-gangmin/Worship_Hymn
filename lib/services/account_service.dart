import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worship_hymn/services/playlist_service.dart';

class AccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Deletes all user data from Firestore (playlists, recent_views)
  Future<void> resetUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    // 1. Delete Playlists and their subcollections (songs)
    final playlistsSnap = await userRef.collection('playlists').get();
    for (var doc in playlistsSnap.docs) {
      // Delete songs subcollection first
      final songsSnap = await doc.reference.collection('songs').get();
      for (var songDoc in songsSnap.docs) {
        await songDoc.reference.delete();
      }
      // Delete playlist document
      await doc.reference.delete();
    }

    // 2. Delete Recent Views
    final recentSnap = await userRef.collection('recent_views').get();
    for (var doc in recentSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Ensure default playlist is recreated
    final playlistService = PlaylistService(uid: uid);
    await playlistService.ensureDefaultPlaylist();
  }

  /// Deletes user data and the Firebase Auth account
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) return;

    // 1. Delete all Firestore data
    await resetUserData(uid);
    
    // 2. Delete user document
    await _db.collection('users').doc(uid).delete();

    // 3. Delete Firebase Auth user
    await user.delete();
  }
}

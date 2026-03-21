import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _col => _firestore.collection('user_profiles');

  Future<void> save(UserProfile profile) async {
    await _col.doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> load(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()! as Map);
      // Inject uid from document path in case it's missing from the fields
      data['uid'] ??= uid;
      return UserProfile.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  /// Appends a venueId to the user's ownedVenueIds list.
  Future<void> addOwnedVenue(String uid, String venueId) async {
    await _col.doc(uid).set(
      {'ownedVenueIds': FieldValue.arrayUnion([venueId])},
      SetOptions(merge: true),
    );
  }

  /// Removes a venueId from the user's ownedVenueIds list.
  Future<void> removeOwnedVenue(String uid, String venueId) async {
    await _col.doc(uid).update({
      'ownedVenueIds': FieldValue.arrayRemove([venueId]),
    });
  }

  /// Atomically increments interest counters for a user after a swipe session.
  /// Uses dot-notation keys + FieldValue.increment so existing profile fields
  /// (name, preferredTypes, etc.) are never overwritten.
  Future<void> updateInterests({
    required String uid,
    required Map<String, int> likedTypesDelta,
    required Map<String, int> likedFeaturesDelta,
    required Map<String, int> preferredPriceDelta,
    required Map<String, int> preferredDistanceDelta,
    required Map<String, int> preferredGroupDelta,
  }) async {
    final updates = <String, dynamic>{
      'totalSessions': FieldValue.increment(1),
    };
    for (final e in likedTypesDelta.entries) {
      updates['likedTypes.${e.key}'] = FieldValue.increment(e.value);
    }
    for (final e in likedFeaturesDelta.entries) {
      updates['likedFeatures.${e.key}'] = FieldValue.increment(e.value);
    }
    for (final e in preferredPriceDelta.entries) {
      updates['preferredPrice.${e.key}'] = FieldValue.increment(e.value);
    }
    for (final e in preferredDistanceDelta.entries) {
      updates['preferredDistance.${e.key}'] = FieldValue.increment(e.value);
    }
    for (final e in preferredGroupDelta.entries) {
      updates['preferredGroup.${e.key}'] = FieldValue.increment(e.value);
    }
    await _col.doc(uid).set(updates, SetOptions(merge: true));
  }
}

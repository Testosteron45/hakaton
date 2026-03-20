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
      return UserProfile.fromMap(doc.data()! as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCloudService {
  UserCloudService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static DocumentReference<Map<String, dynamic>>? get currentUserDoc {
    final user = currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid);
  }

  static Future<void> createUserProfileIfNeeded(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.set({
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static CollectionReference<Map<String, dynamic>>? get portfolioItems {
    final user = currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('portfolioItems');
  }
}

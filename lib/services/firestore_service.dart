// frontend/lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // Initialise le logger

  Future<void> addUserData(String name,String firstName) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'firstname': firstName,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _logger.i('User data added to Firestore'); // Utilise le logger pour les informations
      } catch (e) {
        _logger.e('Error adding user data: $e'); // Utilise le logger pour les erreurs
      }
    }
  }

  Future<DocumentSnapshot?> getUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
        return userData;
      } catch (e) {
        _logger.e('Error retrieving user data: $e'); // Utilise le logger pour les erreurs
        return null;
      }
    }
    return null;
  }
}
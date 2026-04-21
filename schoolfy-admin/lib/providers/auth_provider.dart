import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _userData;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  Map<String, dynamic>? get userData => _userData;
  
  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();
    
    if (user != null) {
      await _checkAdminRole(user.uid);
    } else {
      _isAdmin = false;
      _userData = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _checkAdminRole(String uid) async {
    try {
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (!adminDoc.exists && _user?.email != null) {
        final querySnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: _user!.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          adminDoc = querySnapshot.docs.first;
        }
      }
      
      if (adminDoc.exists) {
        _userData = adminDoc.data() as Map<String, dynamic>?;
        final isActive = _userData?['status'] == 'active';
        _isAdmin = isActive;

        if (isActive) {
          await _firestore.collection('admins').doc(adminDoc.id).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        _isAdmin = false;
        _userData = null;
      }
    } catch (_) {
      _isAdmin = false;
      _userData = null;
    }
  }
  
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Login failed: ${e.code} - ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }
  
  Future<String?> signInWithPhone(String phoneNumber, String verificationCode) async {
    try {
      // For demo purposes - in production, implement proper phone auth flow
      // This would require implementing the full phone verification process
      return 'Phone authentication not implemented in this demo';
    } catch (e) {
      return 'Phone authentication failed: $e';
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<String?> createAdminAccount(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('admins').doc(user.uid).set({
          'email': email.trim(),
          'displayName': 'Admin User',
          'status': 'active',
          'permissions': ['dashboard', 'students', 'guardians', 'pickup_queue', 'reports'],
          'schoolId': 'SCH_001',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
        });
        await user.updateDisplayName('Admin User');
        return null;
      } else {
        return 'Failed to create user account.';
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled. Please enable Email/Password authentication in Firebase Console.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return 'Account creation failed: ${e.code} - ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

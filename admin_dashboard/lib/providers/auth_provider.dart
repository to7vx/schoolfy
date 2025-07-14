import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        print('🔍 DEBUG: Checking admin access for user: $uid');
        print('🔍 DEBUG: User email: ${_user?.email}');
      }
      
      // Check in the admins collection first (by UID)
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      
      if (kDebugMode) {
        print('🔍 DEBUG: Admin document exists by UID: ${adminDoc.exists}');
        print('🔍 DEBUG: Document path: admins/$uid');
      }
      
      // If not found by UID, search by email in admins collection
      if (!adminDoc.exists && _user?.email != null) {
        if (kDebugMode) {
          print('🔍 DEBUG: Searching admins collection by email: ${_user!.email}');
        }
        
        final querySnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: _user!.email)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          adminDoc = querySnapshot.docs.first;
          if (kDebugMode) {
            print('🔍 DEBUG: Found admin document by email with ID: ${adminDoc.id}');
          }
        } else {
          if (kDebugMode) {
            print('🔍 DEBUG: No admin document found by email');
          }
        }
      }
      
      if (kDebugMode && adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>?;
        print('🔍 DEBUG: Admin document data: $data');
        print('🔍 DEBUG: Admin status: ${data?['status']}');
        print('🔍 DEBUG: Admin permissions: ${data?['permissions']}');
      }
      
      if (adminDoc.exists) {
        _userData = adminDoc.data() as Map<String, dynamic>?;
        
        // Check if admin is active
        final isActive = _userData?['status'] == 'active';
        _isAdmin = isActive;
        
        if (kDebugMode) {
          print('🔍 DEBUG: Admin status from document: ${_userData?['status']}');
          print('🔍 DEBUG: Is admin active: $_isAdmin');
        }
        
        // Update last login timestamp
        if (isActive) {
          await _firestore.collection('admins').doc(adminDoc.id).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // No admin document found, but user might still have access through Firestore rules
        // Let's try to read a protected collection to check if they have admin access
        try {
          await _firestore.collection('admins').limit(1).get();
          // If we can read admins collection, user has admin access through rules
          _isAdmin = true;
          _userData = {
            'email': _user!.email,
            'name': 'Admin User',
            'role': 'admin',
            'status': 'active',
            'permissions': {
              'manageStudents': true,
              'manageGuardians': true,
              'viewPickupHistory': true,
              'exportData': true,
            }
          };
          
          if (kDebugMode) {
            print('🔍 DEBUG: User has admin access through Firestore rules');
          }
        } catch (rulesError) {
          _isAdmin = false;
          _userData = null;
          
          if (kDebugMode) {
            print('🔍 DEBUG: No admin document found and no rule-based access, access denied');
          }
        }
      }
    } catch (e) {
      _isAdmin = false;
      _userData = null;
      if (kDebugMode) {
        print('🔍 DEBUG: Error checking admin access: $e');
      }
    }
  }
  
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Attempting sign in with email: $email');
      }
      
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (kDebugMode) {
        print('Firebase authentication successful');
      }
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      }
      
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
      if (kDebugMode) {
        print('General exception during sign in: $e');
      }
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
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
  
  Future<String?> createAdminAccount(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Attempting to create admin account for: $email');
        print('Firebase Auth instance: ${_auth.toString()}');
        print('Current user: ${_auth.currentUser?.toString() ?? 'null'}');
      }

      // Create the user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (kDebugMode) {
        print('User credential created: ${userCredential.user?.uid}');
      }
      
      final User? user = userCredential.user;
      if (user != null) {
        if (kDebugMode) {
          print('Creating Firestore document for user: ${user.uid}');
        }
        
        // Create admin document in the admins collection
        await _firestore.collection('admins').doc(user.uid).set({
          'email': email.trim(),
          'displayName': 'Admin User',
          'status': 'active',
          'permissions': ['dashboard', 'students', 'guardians', 'pickup_queue', 'reports'],
          'schoolId': 'SCH_001', // Default school
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
        });
        
        if (kDebugMode) {
          print('Firestore document created successfully');
        }
        
        // Update display name if needed
        await user.updateDisplayName('Admin User');
        
        if (kDebugMode) {
          print('Admin account created successfully: ${user.uid}');
        }
        
        return null; // Success
      } else {
        if (kDebugMode) {
          print('User is null after creation');
        }
        return 'Failed to create user account.';
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
        print('Error details: ${e.toString()}');
      }
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
      if (kDebugMode) {
        print('General exception: $e');
        print('Exception type: ${e.runtimeType}');
      }
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      rethrow;
    }
  }
}

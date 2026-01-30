import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final _authStateController = StreamController<dynamic>.broadcast();
  bool _isSimulatedLoggedIn = false;
  String? _simulatedName;
  String? _simulatedRole;

  AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;

  bool get isFirebaseAvailable {
    try {
      return _auth != null;
    } catch (_) {
      return false;
    }
  }

  // Stream for auth state changes
  Stream<dynamic> get authStateChanges async* {
    if (isFirebaseAvailable) {
      yield* _auth!.authStateChanges();
    } else {
      yield _isSimulatedLoggedIn ? 'simulated_user' : null;
      yield* _authStateController.stream;
    }
  }

  // Sign in with email and password
  Future<dynamic> signInWithEmail(String email, String password) async {
    if (isFirebaseAvailable) {
      try {
        UserCredential result = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // SYNC TO MONGODB AS SOON AS SIGNED IN
        if (result.user != null) {
          debugPrint("DEBUG: User signed in. Syncing profile to MongoDB...");
          // We trigger getUserRole to ensure the profile exists in MongoDB
          await getUserRole();
        }

        return result;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        throw 'An unexpected error occurred: $e';
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      _isSimulatedLoggedIn = true;
      _simulatedName = email.split('@')[0].toUpperCase(); 
      _simulatedRole = 'Student';
      _authStateController.add('simulated_user');
      return 'simulated_user';
    }
  }

  // Register with email and password
  Future<dynamic> signUpWithEmail(String email, String password, String name, String role, {Map<String, dynamic>? extraData}) async {
    if (isFirebaseAvailable) {
      try {
        UserCredential result = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        
        await result.user?.updateDisplayName(name);
        
        debugPrint("DEBUG: Account created in Auth. Saving to MongoDB...");

        // Prepare full profile data
        Map<String, dynamic> profileData = {
          'uid': result.user!.uid,
          'name': name,
          'email': email.trim(),
          'role': role,
          'department': extraData?['department'] ?? 'Computer Science',
          'phone': extraData?['phone'] ?? '+91 98765 43210',
          'idNumber': extraData?['idNumber'] ?? (role == 'Faculty' ? 'PROF-101' : 'CF2024-001'),
        };

        // Add any other extra data (like yearOfStudy, notifications)
        if (extraData != null) {
          profileData.addAll(extraData);
        }

        // Save to MongoDB (PRIMARY DATABASE)
        await ApiService.saveUser(profileData);

        // Optional: Save to Firestore (don't let errors here block MongoDB)
        try {
          await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
            'uid': result.user!.uid,
            'name': name,
            'email': email.trim(),
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint("DEBUG: Firestore sync ignored: $e");
        }

        return result;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        throw 'Signup failed: $e';
      }
    } else {
      _isSimulatedLoggedIn = true;
      _authStateController.add('simulated_user');
      return 'simulated_user';
    }
  }

  // Get current user role (PRIMARY: MongoDB)
  Future<String?> getUserRole() async {
    try {
      if (isFirebaseAvailable) {
        User? user = _auth?.currentUser;
        if (user == null) return null;

        debugPrint("DEBUG: Fetching role for ${user.uid} from MongoDB...");
        final mongoProfile = await ApiService.fetchUserProfile(user.uid);
        
        if (mongoProfile != null && mongoProfile['role'] != null) {
          return mongoProfile['role'];
        }

        // FALLBACK/SYNC: If not in MongoDB, try Firestore and sync it back
        debugPrint("DEBUG: User not in MongoDB. Syncing defaults...");
        String foundRole = 'Student';
        
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            foundRole = doc.data()?['role'] ?? 'Student';
          }
        } catch (e) {
           debugPrint("DEBUG: Firestore fallback failed: $e");
        }

        // Ensure user exists in MongoDB now with more fields
        await ApiService.saveUser({
          'uid': user.uid,
          'name': user.displayName ?? foundRole, // Default name is now the role (Student/Faculty)
          'email': user.email,
          'role': foundRole,
          'department': 'Computer Science',
          'phone': '+91 98765 43210',
          'idNumber': foundRole == 'Faculty' ? 'CF-PROF-001' : 'CF2024001',
        });

        return foundRole;
      }
      return _simulatedRole ?? 'Student';
    } catch (e) {
      debugPrint("DEBUG: getUserRole Error: $e");
      return 'Student'; 
    }
  }

  // Get full profile from MongoDB
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (isFirebaseAvailable) {
        User? user = _auth?.currentUser;
        if (user == null) return null;
        return await ApiService.fetchUserProfile(user.uid);
      }
      return {
        'name': _simulatedName ?? 'Demo User',
        'email': 'demo@campus.edu',
        'role': 'Student',
        'department': 'Computer Science',
        'phone': '+91 98765 43210',
        'idNumber': 'CF2024001',
      };
    } catch (e) {
      debugPrint("DEBUG: getUserProfile Error: $e");
      return null;
    }
  }

  // Fetch all users with role 'Faculty' from MongoDB API 
  Future<List<Map<String, dynamic>>> getFacultyList() async {
    try {
      debugPrint("DEBUG: getFacultyList - Fetching from MongoDB...");
      return await ApiService.fetchFaculties();
    } catch (e) {
      debugPrint("DEBUG: getFacultyList Error: $e");
      return [];
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      await _auth!.signOut();
    } else {
      _isSimulatedLoggedIn = false;
      _authStateController.add(null);
    }
  }

  String get displayName => _auth?.currentUser?.displayName ?? 'User';
  String get userEmail => _auth?.currentUser?.email ?? 'No email';

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    if (isFirebaseAvailable) {
      await _auth!.sendPasswordResetEmail(email: email);
    }
  }

  // Delete User Account
  Future<void> deleteUserAccount() async {
    if (isFirebaseAvailable) {
      try {
        User? user = _auth!.currentUser;
        if (user != null) {
          await user.delete();
          await signOut();
        }
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        throw 'Failed to delete account. Please try re-logging in.';
      }
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'email-already-in-use': return 'Account already exists.';
      case 'requires-recent-login': return 'Security: Please re-login to delete account.';
      default: return e.message ?? 'Authentication failed.';
    }
  }
}

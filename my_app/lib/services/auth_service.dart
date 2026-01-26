import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final _authStateController = StreamController<dynamic>.broadcast();
  bool _isSimulatedLoggedIn = false;
  String? _simulatedName;

  AuthService._internal() {
    // Initial emission for simulation if Firebase is not available
    if (!isFirebaseAvailable) {
      _authStateController.add(null);
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isFirebaseAvailable {
    try {
      if (kIsWeb) {
        // On web, checking apps is safer
        return Firebase.apps.isNotEmpty;
      }
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
      // For simulation, emit current state immediately, then future updates
      yield _isSimulatedLoggedIn ? 'simulated_user' : null;
      yield* _authStateController.stream;
    }
  }

  // Sign in with email and password
  Future<dynamic> signInWithEmail(String email, String password) async {
    if (isFirebaseAvailable) {
      try {
        return await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        throw 'An unexpected error occurred: $e';
      }
    } else {
      // Simulation for web/demo
      await Future.delayed(const Duration(seconds: 1));
      _isSimulatedLoggedIn = true;
      // Extract a name from email for dynamic feel in demo mode
      _simulatedName = email.split('@')[0].capitalize(); 
      _authStateController.add('simulated_user');
      return 'simulated_user';
    }
  }

  // Register with email and password
  Future<dynamic> signUpWithEmail(String email, String password, String name) async {
    if (isFirebaseAvailable) {
      try {
        UserCredential result = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        await result.user?.updateDisplayName(name);
        return result;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        throw 'An unexpected error occurred during signup: $e';
      }
    } else {
      // Simulation for web/demo
      await Future.delayed(const Duration(seconds: 1));
      _isSimulatedLoggedIn = true;
      _simulatedName = name;
      _authStateController.add('simulated_user');
      return 'simulated_user';
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

  String get displayName {
    if (isFirebaseAvailable) {
      return _auth!.currentUser?.displayName ?? 'User';
    }
    return _simulatedName ?? 'Demo User';
  }

  String get userEmail {
    if (isFirebaseAvailable) {
      return _auth!.currentUser?.email ?? 'Not available';
    }
    return 'demo@campus.edu';
  }

  // Helper to handle Firebase exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

extension StringExtension on String {
    String capitalize() {
      if (this.isEmpty) return this;
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
}

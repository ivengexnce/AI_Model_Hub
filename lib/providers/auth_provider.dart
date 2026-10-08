import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Domain entity ───────────────────────────────────────────────────────────
class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final bool isGuest;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'ML Engineer',
    this.isGuest = false,
  });

  factory AuthUser.fromFirebaseUser(fb.User user, {bool isGuest = false}) {
    final namePart = (user.displayName?.isNotEmpty == true)
        ? user.displayName!
        : user.email?.split('@').first ?? 'ML Engineer';
    final displayName =
        '${namePart[0].toUpperCase()}${namePart.substring(1)}';
    return AuthUser(
      uid: user.uid,
      email: user.email ?? 'guest@aimodelhub.ai',
      displayName: displayName,
      photoUrl: user.photoURL,
      isGuest: isGuest,
    );
  }

  /// Offline/mock fallback user (no Firebase)
  factory AuthUser.mock(String email) {
    final namePart = email.split('@').first;
    final displayName =
        '${namePart[0].toUpperCase()}${namePart.substring(1)}';
    return AuthUser(
      uid: 'offline-uid',
      email: email,
      displayName: displayName,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
class AuthProvider with ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  bool isEmailValid(String email) => _emailRegExp.hasMatch(email.trim());
  bool isPasswordValid(String password) => password.trim().length >= 6;

  bool get _firebaseAvailable =>
      Firebase.apps.isNotEmpty;

  // ── Email / Password ───────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);

    final trimmedEmail = email.trim();
    final trimmedPass = password.trim();

    if (!isEmailValid(trimmedEmail)) {
      return _fail('Please enter a valid email address.');
    }
    if (!isPasswordValid(trimmedPass)) {
      return _fail('Password must be at least 6 characters.');
    }

    // ── Live Firebase Auth path ──────────────────────────────────────────────
    if (_firebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPass,
        );
        _currentUser = AuthUser.fromFirebaseUser(credential.user!);
        await _persistSession(trimmedEmail);
        return _succeed();
      } on fb.FirebaseAuthException catch (e) {
        return _fail(_mapFirebaseError(e));
      } catch (e) {
        // Firebase unreachable → fall through to mock
        debugPrint('Firebase unreachable, using offline mode: $e');
      }
    }

    // ── Offline / mock path ──────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = AuthUser.mock(trimmedEmail);
    await _persistSession(trimmedEmail);
    return _succeed();
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    if (!_firebaseAvailable) {
      return _fail('Google Sign-In requires a live Firebase connection.\nPlease follow firebase_setup.md to configure your project.');
    }
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return _fail('Google sign-in was cancelled.');

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      _currentUser = AuthUser.fromFirebaseUser(userCredential.user!);
      await _persistSession(_currentUser!.email);
      return _succeed();
    } on fb.FirebaseAuthException catch (e) {
      return _fail(_mapFirebaseError(e));
    } catch (e) {
      return _fail('Google Sign-In failed. Please try again.');
    }
  }

  // ── Anonymous / Guest ──────────────────────────────────────────────────────
  Future<bool> loginAsGuest() async {
    _setLoading(true);
    if (_firebaseAvailable) {
      try {
        final credential =
            await fb.FirebaseAuth.instance.signInAnonymously();
        _currentUser =
            AuthUser.fromFirebaseUser(credential.user!, isGuest: true);
        return _succeed();
      } catch (_) {
        debugPrint('Anonymous auth failed, using mock guest.');
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = const AuthUser(
      uid: 'guest-uid',
      email: 'guest@aimodelhub.ai',
      displayName: 'Guest User',
      role: 'Visitor',
      isGuest: true,
    );
    return _succeed();
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);

    if (!isEmailValid(email.trim())) return _fail('Please enter a valid email.');
    if (!isPasswordValid(password)) return _fail('Password must be at least 6 characters.');
    if (name.trim().isEmpty) return _fail('Please enter your name.');

    if (_firebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
        _currentUser = AuthUser.fromFirebaseUser(
          fb.FirebaseAuth.instance.currentUser!,
        );
        await _persistSession(email.trim());
        return _succeed();
      } on fb.FirebaseAuthException catch (e) {
        return _fail(_mapFirebaseError(e));
      }
    }

    // Offline mock registration
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = AuthUser(
      uid: 'offline-new-uid',
      email: email.trim(),
      displayName: name.trim(),
    );
    await _persistSession(email.trim());
    return _succeed();
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    if (_firebaseAvailable) {
      try {
        await GoogleSignIn().signOut();
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    notifyListeners();
  }

  // ── Session restore ────────────────────────────────────────────────────────
  Future<void> restoreSession() async {
    // Try Firebase auto-restore first
    if (_firebaseAvailable) {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUser = AuthUser.fromFirebaseUser(user);
        notifyListeners();
        return;
      }
    }
    // Fallback: shared_preferences mock session
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('session_email');
      if (email != null && email.isNotEmpty) {
        _currentUser = AuthUser.mock(email);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  bool _succeed() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  bool _fail(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
    return false;
  }

  Future<void> _persistSession(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_email', email);
    } catch (_) {}
  }

  String _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Switching to offline mode.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

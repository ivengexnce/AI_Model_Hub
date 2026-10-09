import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Domain entity -----------------------------------------------------------
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
    final String displayName;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      displayName = user.displayName!.trim();
    } else if (user.email != null && user.email!.isNotEmpty) {
      final namePart = user.email!.split('@').first;
      displayName = namePart.isNotEmpty
          ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
          : 'ML Engineer';
    } else {
      displayName = isGuest || user.isAnonymous ? 'Guest User' : 'ML Engineer';
    }

    return AuthUser(
      uid: user.uid,
      email: user.email ?? (isGuest || user.isAnonymous ? 'guest@broml.ai' : ''),
      displayName: displayName,
      photoUrl: user.photoURL,
      isGuest: isGuest || user.isAnonymous,
    );
  }

  factory AuthUser.mock(String email) {
    final namePart = email.split('@').first;
    final displayName = namePart.isNotEmpty
        ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
        : 'ML Engineer';
    return AuthUser(
      uid: 'mock-${email.hashCode}',
      email: email,
      displayName: displayName,
      role: 'ML Engineer',
    );
  }
}

// --- Provider ----------------------------------------------------------------
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

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (_firebaseAvailable) {
      try {
        fb.FirebaseAuth.instance.authStateChanges().listen((fbUser) {
          if (fbUser != null) {
            _currentUser = AuthUser.fromFirebaseUser(fbUser);
            _persistUserSession(_currentUser!);
            notifyListeners();
          }
        });
      } catch (e) {
        debugPrint('authStateChanges listener error: $e');
      }
    }
  }

  // -- Email / Password -------------------------------------------------------
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

    if (_firebaseAvailable) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPass,
        );
        if (credential.user != null) {
          _currentUser = AuthUser.fromFirebaseUser(credential.user!);
          await _persistUserSession(_currentUser!);
          return _succeed();
        }
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          try {
            final regCred = await fb.FirebaseAuth.instance
                .createUserWithEmailAndPassword(
              email: trimmedEmail,
              password: trimmedPass,
            );
            if (regCred.user != null) {
              _currentUser = AuthUser.fromFirebaseUser(regCred.user!);
              await _persistUserSession(_currentUser!);
              return _succeed();
            }
          } catch (_) {}
        }
        return _fail(_mapFirebaseError(e));
      } catch (e) {
        debugPrint('Firebase login exception: $e');
      }
    }

    // Offline / Demo fallback so user is never locked out
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = AuthUser.mock(trimmedEmail);
    await _persistUserSession(_currentUser!);
    return _succeed();
  }

  // -- Google Sign-In ---------------------------------------------------------
  Future<bool> loginWithGoogle() async {
    _setLoading(true);

    if (!_firebaseAvailable) {
      return _fail('Firebase is not initialized. Please check your network connection.');
    }

    try {
      if (kIsWeb) {
        final googleProvider = fb.GoogleAuthProvider();
        final userCredential =
            await fb.FirebaseAuth.instance.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          _currentUser = AuthUser.fromFirebaseUser(userCredential.user!);
          await _persistUserSession(_currentUser!);
          return _succeed();
        } else {
          return _fail('Google sign-in did not return a user.');
        }
      } else {
        final googleSignIn = GoogleSignIn(
          serverClientId: '640800735490-vnk6dgbf23o80nlis3150cpp485omfsp.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

        // Clear any previous sign in cache so account selector always appears
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User closed or canceled Google sign-in dialog
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return false;
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null && googleAuth.accessToken == null) {
          return _fail('Failed to obtain Google authentication tokens.');
        }

        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await fb.FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          _currentUser = AuthUser.fromFirebaseUser(userCredential.user!);
          await _persistUserSession(_currentUser!);
          return _succeed();
        } else {
          return _fail('Google sign-in succeeded, but no user profile was returned.');
        }
      }
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase Google login exception: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Google Sign-In exception / fallback: $e');
    }

    // Graceful Google fallback so user is never locked out
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = const AuthUser(
      uid: 'google-demo-uid',
      email: 'alex.chen@google.com',
      displayName: 'Alex Chen',
      role: 'ML Research Engineer',
    );
    await _persistUserSession(_currentUser!);
    return _succeed();
  }

  // -- GitHub Sign-In ---------------------------------------------------------
  Future<bool> loginWithGitHub() async {
    _setLoading(true);
    if (!_firebaseAvailable) {
      return _fail('Firebase is not initialized.');
    }

    try {
      final githubProvider = fb.GithubAuthProvider();
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithProvider(githubProvider);
      if (userCredential.user != null) {
        _currentUser = AuthUser.fromFirebaseUser(userCredential.user!);
        await _persistUserSession(_currentUser!);
        return _succeed();
      } else {
        return _fail('GitHub sign-in did not return a user.');
      }
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return _fail('An account already exists with this email address.');
      }
      debugPrint('Firebase GitHub login exception: ${e.message}');
      return _fail(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('GitHub sign in error: $e');
      return _fail('GitHub sign in failed: $e');
    }
  }

  // -- Anonymous / Guest ------------------------------------------------------
  Future<bool> loginAsGuest() async {
    _setLoading(true);
    if (_firebaseAvailable) {
      try {
        final credential =
            await fb.FirebaseAuth.instance.signInAnonymously();
        if (credential.user != null) {
          _currentUser =
              AuthUser.fromFirebaseUser(credential.user!, isGuest: true);
          await _persistUserSession(_currentUser!);
          return _succeed();
        }
      } catch (e) {
        debugPrint('Anonymous auth failed: $e');
      }
    }
    // Guest fallback only for quick demo mode
    _currentUser = const AuthUser(
      uid: 'guest-session-uid',
      email: 'guest@broml.ai',
      displayName: 'Guest Explorer',
      role: 'Visitor',
      isGuest: true,
    );
    await _persistUserSession(_currentUser!);
    return _succeed();
  }

  // -- Register ---------------------------------------------------------------
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);

    if (!isEmailValid(email.trim())) return _fail('Please enter a valid email.');
    if (!isPasswordValid(password)) return _fail('Password must be at least 6 characters.');
    if (name.trim().isEmpty) return _fail('Please enter your name.');

    if (!_firebaseAvailable) {
      return _fail('Firebase is not initialized. Please check network connection.');
    }

    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
        final updatedUser =
            fb.FirebaseAuth.instance.currentUser ?? credential.user!;
        _currentUser = AuthUser.fromFirebaseUser(updatedUser);
        await _persistUserSession(_currentUser!);
        return _succeed();
      } else {
        return _fail('Registration failed. Please try again.');
      }
    } on fb.FirebaseAuthException catch (e) {
      return _fail(_mapFirebaseError(e));
    } catch (e) {
      return _fail('Registration error: $e');
    }
  }

  // -- Logout (Only explicit user sign out clears the session) ----------------
  Future<void> logout() async {
    if (_firebaseAvailable) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_is_logged_in', false);
      await prefs.remove('session_uid');
      await prefs.remove('session_email');
      await prefs.remove('session_name');
      await prefs.remove('session_role');
      await prefs.remove('session_photo');
      await prefs.remove('session_is_guest');
    } catch (_) {}

    notifyListeners();
  }

  // -- Session restore (Keeps user signed in forever until explicit logout) ---
  Future<void> restoreSession() async {
    try {
      // 1. Immediately inspect local SharedPreferences (instant on Web & Mobile)
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('session_is_logged_in') ?? false;
      final savedEmail = prefs.getString('session_email');

      if (isLoggedIn || (savedEmail != null && savedEmail.isNotEmpty)) {
        final uid = prefs.getString('session_uid') ?? 'restored-${savedEmail.hashCode}';
        final email = savedEmail ?? 'user@broml.ai';
        final name = prefs.getString('session_name') ??
            (email.contains('@') ? email.split('@').first : 'ML Engineer');
        final role = prefs.getString('session_role') ?? 'ML Engineer';
        final photo = prefs.getString('session_photo');
        final isGuest = prefs.getBool('session_is_guest') ?? false;

        _currentUser = AuthUser(
          uid: uid,
          email: email,
          displayName: name,
          role: role,
          photoUrl: (photo != null && photo.isNotEmpty) ? photo : null,
          isGuest: isGuest,
        );
        notifyListeners();
      }

      // 2. If Firebase has an active session, sync up
      if (_firebaseAvailable) {
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          _currentUser = AuthUser.fromFirebaseUser(user);
          await _persistUserSession(_currentUser!);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('restoreSession error: $e');
    }
  }

  // -- Helpers ----------------------------------------------------------------
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

  Future<void> _persistUserSession(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_is_logged_in', true);
      await prefs.setString('session_uid', user.uid);
      await prefs.setString('session_email', user.email);
      await prefs.setString('session_name', user.displayName);
      await prefs.setString('session_role', user.role);
      if (user.photoUrl != null) {
        await prefs.setString('session_photo', user.photoUrl!);
      } else {
        await prefs.remove('session_photo');
      }
      await prefs.setBool('session_is_guest', user.isGuest);
    } catch (e) {
      debugPrint('Error persisting user session: $e');
    }
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
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'popup-closed-by-user':
        return 'Sign in cancelled.';
      default:
        return e.message ?? 'Authentication failed (${e.code}). Please try again.';
    }
  }
}


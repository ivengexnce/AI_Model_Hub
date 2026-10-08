import 'package:flutter/material.dart';

class AuthUser {
  final String email;
  final String displayName;
  final String role;

  const AuthUser({
    required this.email,
    required this.displayName,
    this.role = 'ML Engineer',
  });
}

class AuthProvider with ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  bool isEmailValid(String email) => _emailRegExp.hasMatch(email.trim());
  bool isPasswordValid(String password) => password.trim().length >= 6;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final trimmedEmail = email.trim();
    final trimmedPass = password.trim();

    if (!isEmailValid(trimmedEmail)) {
      _errorMessage = 'Please enter a valid email address.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!isPasswordValid(trimmedPass)) {
      _errorMessage = 'Password must be at least 6 characters.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final namePart = trimmedEmail.split('@').first;
    final displayName = namePart.isNotEmpty
        ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
        : 'ML Developer';

    _currentUser = AuthUser(
      email: trimmedEmail,
      displayName: displayName,
    );
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> loginAsGuest() async {
    return login('developer@aimodelhub.ai', 'neuralnetwork2026');
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group("AuthProvider Automated Verification", () {
    test("Initial state is unauthenticated and clean", () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNull);
      expect(auth.isLoading, isFalse);
    });

    test("Validation logic correctly validates emails and passwords", () {
      final auth = AuthProvider();
      expect(auth.isEmailValid("test@example.com"), isTrue);
      expect(auth.isEmailValid("invalid-email"), isFalse);
      expect(auth.isEmailValid("   "), isFalse);

      expect(auth.isPasswordValid("123456"), isTrue);
      expect(auth.isPasswordValid("12345"), isFalse);
    });

    test("Guest login creates a guest session with real non-mock metadata", () async {
      final auth = AuthProvider();
      final result = await auth.loginAsGuest();

      expect(result, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.isGuest, isTrue);
      expect(auth.currentUser?.email, isNot(contains("alex.chen")));
      expect(auth.currentUser?.displayName, isNot(contains("Alex Chen")));
    });

    test("Logout completely purges the session", () async {
      final auth = AuthProvider();
      await auth.loginAsGuest();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNull);
    });

    test("Invalid email submission fails gracefully without creating user", () async {
      final auth = AuthProvider();
      final result = await auth.login("not-an-email", "secret123");

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNotNull);
      expect(auth.errorMessage, contains("valid email"));
    });

    test("Empty/short password submission fails gracefully without creating user", () async {
      final auth = AuthProvider();
      final result = await auth.login("user@broml.ai", "123");

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNotNull);
      expect(auth.errorMessage, contains("at least 6 characters"));
    });
  });
}

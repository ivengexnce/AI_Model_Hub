import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/model_provider.dart';
import 'screens/login_screen.dart';
import 'screens/model_list_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode on mobile only
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBgfZlPIRHuEy1E9YB66zGZNhG22I8Xcbg',
          authDomain: 'broml-app.firebaseapp.com',
          appId: '1:640800735490:web:broml_web_placeholder',
          messagingSenderId: '640800735490',
          projectId: 'broml-app',
          storageBucket: 'broml-app.firebasestorage.app',
        ),
      );
    } else {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyBgfZlPIRHuEy1E9YB66zGZNhG22I8Xcbg',
            appId: '1:640800735490:android:e5bd1d38e364882b2b821b',
            messagingSenderId: '640800735490',
            projectId: 'broml-app',
            storageBucket: 'broml-app.firebasestorage.app',
          ),
        );
      }
    }
    debugPrint('Firebase initialised for broml-app.');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const AiModelHubApp());
}

class AiModelHubApp extends StatelessWidget {
  const AiModelHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
      ],
      child: MaterialApp(
        title: 'BroML',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const _AppEntry(),
      ),
    );
  }
}

// Root route: restores the session, then swaps between login and the app.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.restoreSession();
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: auth.isAuthenticated
            ? const ModelListScreen(key: ValueKey('list'))
            : const LoginScreen(key: ValueKey('login')),
      ),
    );
  }
}


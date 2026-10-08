import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/model_provider.dart';
import 'screens/login_screen.dart';
import 'screens/model_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Try live Firebase; fall back gracefully if not configured yet
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDemoKeyForModelHubOfflineMode123',
        appId: '1:100000000000:android:1000000000000000000000',
        messagingSenderId: '100000000000',
        projectId: 'ai-model-hub-demo',
        storageBucket: 'ai-model-hub-demo.appspot.com',
      ),
    );
    debugPrint('Firebase initialised (offline demo keys).');
  } catch (e) {
    debugPrint('Firebase offline fallback mode: $e');
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
        theme: _buildTheme(),
        home: const _AppEntry(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const seed = Colors.indigo;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: const Color(0xFF0D0E1A),
        surfaceContainerHighest: const Color(0xFF181929),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0E1A),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF181929),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF3949AB),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222336),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
    );
  }
}

// ── Root route – restores session before deciding which screen to show ────────
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
      // Splash / loading
      return const Scaffold(
        backgroundColor: Color(0xFF0D0E1A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.indigoAccent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) =>
          auth.isAuthenticated ? const ModelListScreen() : const LoginScreen(),
    );
  }
}

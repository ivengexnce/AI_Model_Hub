import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/model_provider.dart';
import 'screens/login_screen.dart';
import 'screens/model_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  } catch (e) {
    debugPrint('Firebase operating in offline fallback mode.');
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
        title: 'AI Model Hub & Zoo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated
                ? const ModelListScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}

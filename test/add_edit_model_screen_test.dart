import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/providers/auth_provider.dart';
import 'package:ai_model_hub/providers/model_provider.dart';
import 'package:ai_model_hub/screens/add_edit_model_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableScreen({Widget? child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
      ],
      child: MaterialApp(
        home: child ?? const AddEditModelScreen(),
      ),
    );
  }

  group('AddEditModelScreen UI & Form Validation Tests', () {
    testWidgets('Renders all required form fields and labels', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New model'), findsOneWidget);
      expect(find.text('Model name'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Framework'), findsOneWidget);
      expect(find.text('Accuracy (%)'), findsOneWidget);
      expect(find.text('Latency (ms)'), findsOneWidget);
      expect(find.text('Dataset'), findsOneWidget);
      expect(find.text('GitHub Repository Link (Optional)'), findsOneWidget);
      expect(find.text('Publish model'), findsOneWidget);
    });

    testWidgets('Displays validation errors when submitting empty form fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap publish without filling out required model name
      final publishBtn = find.text('Publish model');
      await tester.ensureVisible(publishBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(publishBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enter a model name (at least 2 chars)'), findsOneWidget);
    });

    testWidgets('Rejects non-HTTPS or unsafe URLs in GitHub link field', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pump(const Duration(milliseconds: 300));

      // Enter a valid name
      final nameField = find.widgetWithText(TextFormField, 'Model name');
      await tester.enterText(nameField, 'Test Neural Net');
      await tester.pump(const Duration(milliseconds: 100));

      // Enter an unsafe URL
      final urlField = find.widgetWithText(TextFormField, 'GitHub Repository Link (Optional)');
      await tester.ensureVisible(urlField);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(urlField, 'http://insecure-site.com');
      await tester.pump(const Duration(milliseconds: 100));

      // Tap publish
      final publishBtn = find.text('Publish model');
      await tester.ensureVisible(publishBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(publishBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('URL must begin with https://'), findsOneWidget);
    });
  });
}

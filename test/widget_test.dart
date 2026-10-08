import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts on LoginScreen and navigates to Model Hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AiModelHubApp());
    // Pump through the async session restore check
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('BroML'), findsOneWidget);
    expect(find.textContaining('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In to BroML Hub'), findsOneWidget);

    // Ensure demo button is visible and tap
    final demoBtn = find.text('Quick Demo Sign-In (Guest)');
    await tester.ensureVisible(demoBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(demoBtn);
    await tester.pump(const Duration(milliseconds: 1200));

    // Verify navigating to the Model List screen
    expect(find.text('Models Registered'), findsOneWidget);
  });
}

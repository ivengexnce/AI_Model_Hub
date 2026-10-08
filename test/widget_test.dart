import 'package:flutter_test/flutter_test.dart';
import 'package:ai_model_hub/main.dart';

void main() {
  testWidgets('App starts on LoginScreen and navigates to Model Hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AiModelHubApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BroML'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
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

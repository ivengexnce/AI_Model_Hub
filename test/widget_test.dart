import 'package:flutter/material.dart';
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

    // Verify account popup menu button is present and trigger logout
    final popupBtnFinder = find.byType(PopupMenuButton<String>);
    expect(popupBtnFinder, findsOneWidget);
    final popupBtn = tester.widget<PopupMenuButton<String>>(popupBtnFinder);
    popupBtn.onSelected?.call('logout');

    // Allow async logout and route transition to finish
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify navigating back to LoginScreen
    expect(find.text('Sign In to BroML Hub'), findsOneWidget);
  });
}

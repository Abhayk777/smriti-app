// Smoke test for the app shell: MyApp must render the login screen.
// MyApp is pumped directly rather than calling main(), so this test does not
// require a live Supabase.initialize().

import 'package:flutter_test/flutter_test.dart';

import 'package:smriti/main.dart';
import 'package:smriti/screens/login_screen.dart';

void main() {
  testWidgets('MyApp shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
  });
}

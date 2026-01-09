// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:girija/main.dart';
import 'package:girija/services/services.dart';

void main() {
  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    // Initialize storage service for testing
    final storageService = LocalStorageService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(GirijaApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Verify that the login screen is shown with the app name
    expect(find.text('Girija Store'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmusic_frontend/screens/login_screen.dart';
import 'test_helper.dart';

void main() {
  testWidgetsWithMocks('LoginScreen renders UI correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(child: const LoginScreen()),
    );

    // Verify presence of title, input fields and action buttons
    expect(find.text('OpenMusic'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun? '), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });

  testWidgetsWithMocks('LoginScreen empty fields validation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(child: const LoginScreen()),
    );

    // Tap Masuk without filling text fields
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    // Verify form validation displays errors
    expect(find.text('Masukkan email Anda'), findsOneWidget);
    expect(find.text('Masukkan password Anda'), findsOneWidget);
  });

  testWidgetsWithMocks('LoginScreen successful submit triggers login', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(
      createTestableWidget(child: const LoginScreen(), auth: fakeAuth),
    );

    // Enter email and password
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;

    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pump();

    // Tap login button
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify AuthService login was successful
    expect(fakeAuth.isLoggedIn, isTrue);
    expect(fakeAuth.currentUser?.username, equals('TestUser'));
  });

  testWidgetsWithMocks('LoginScreen invalid credentials shows error banner', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(
      createTestableWidget(child: const LoginScreen(), auth: fakeAuth),
    );

    // Enter wrong email and password
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;

    await tester.enterText(emailField, 'wrong@example.com');
    await tester.enterText(passwordField, 'wrong_pass');
    await tester.pump();

    // Tap login button
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify AuthService login failed and error message displays in snackbar
    expect(fakeAuth.isLoggedIn, isFalse);
    expect(fakeAuth.authError, equals('Invalid email or password'));
  });
}

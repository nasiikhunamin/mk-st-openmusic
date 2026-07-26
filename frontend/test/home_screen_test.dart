import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmusic_frontend/screens/home_screen.dart';
import 'test_helper.dart';

void main() {
  testWidgetsWithMocks('HomeScreen renders headers, bento grid and search bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(child: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    // Verify app bar logo
    expect(find.text('OpenMusic'), findsOneWidget);

    // Verify simulated search bar placeholder
    expect(find.text('Artis, lagu, atau genre...'), findsOneWidget);

    // Verify Bento grid cards
    expect(find.text('NEW RELEASE'), findsOneWidget);
    expect(find.text('Daily Mix'), findsOneWidget);
    expect(find.text('Untuk Anda'), findsOneWidget);
    expect(find.text('Putar'), findsOneWidget);

    // Verify lists headers
    expect(find.text('Trending Tracks'), findsOneWidget);
    expect(find.text('Trending Artists'), findsOneWidget);
    expect(find.text('Because you like Synthwave'), findsOneWidget);
  });

  testWidgetsWithMocks('HomeScreen tapping search bar triggers callback', (WidgetTester tester) async {
    bool callbackTriggered = false;
    
    await tester.pumpWidget(
      createTestableWidget(
        child: HomeScreen(
          onSearchTap: () {
            callbackTriggered = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the search bar container
    await tester.tap(find.text('Artis, lagu, atau genre...'));
    await tester.pumpAndSettle();

    // Verify callback was triggered
    expect(callbackTriggered, isTrue);
  });
}

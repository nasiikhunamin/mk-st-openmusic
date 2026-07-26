import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openmusic_frontend/main.dart';
import 'package:openmusic_frontend/screens/home_wrapper.dart';
import 'package:openmusic_frontend/screens/login_screen.dart';
import '../test/test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithMocks('End-to-End User Journey Test', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    final fakePlaylist = FakePlaylistService();
    final fakeFavorites = FakeFavoritesService();
    final fakeHistory = FakeHistoryService();

    // Boot OpenMusicApp with our mock/fake services
    await tester.pumpWidget(
      createTestableWidget(
        child: const AuthGate(),
        auth: fakeAuth,
        playlist: fakePlaylist,
        favorites: fakeFavorites,
        history: fakeHistory,
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify we start on the LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // 2. Input email and password, then tap login
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;

    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pump();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // 3. Verify transition to HomeWrapper (Home tab active)
    expect(find.byType(HomeWrapper), findsOneWidget);
    expect(fakeAuth.isLoggedIn, isTrue);

    // 4. Tap the simulated search bar on HomeScreen, which switches tab to Search Screen (Cari)
    await tester.tap(find.text('Artis, lagu, atau genre...'));
    await tester.pumpAndSettle();

    // 5. Navigate to Library tab by tapping 'Koleksi'
    await tester.tap(find.text('Koleksi'));
    await tester.pumpAndSettle();

    // 6. Verify we are in the Library Screen. Tap FloatingActionButton to create a new playlist
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 7. Verify the dialog opens, enter the playlist name and submit
    expect(find.text('Buat Playlist Baru'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'My Integration Playlist');
    await tester.tap(find.text('Buat'));
    await tester.pumpAndSettle();

    // 8. Verify the new playlist is successfully added and rendered
    expect(find.text('My Integration Playlist'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmusic_frontend/screens/library_screen.dart';
import 'test_helper.dart';

void main() {
  testWidgetsWithMocks('LibraryScreen renders tabs and lists correctly', (WidgetTester tester) async {
    final fakePlaylist = FakePlaylistService();
    final fakeFavorites = FakeFavoritesService();
    final fakeHistory = FakeHistoryService();

    await tester.pumpWidget(
      createTestableWidget(
        child: const LibraryScreen(),
        playlist: fakePlaylist,
        favorites: fakeFavorites,
        history: fakeHistory,
      ),
    );

    // Initial state loading or fetching data
    await tester.pumpAndSettle();

    // Verify Title and Tabs
    expect(find.text('Koleksi Musik'), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('Favorit'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    // Verify Playlist listing renders items from FakePlaylistService
    expect(find.text('Chill Beats'), findsOneWidget);
    expect(find.text('5 Lagu'), findsOneWidget);
    expect(find.text('Rock Classics'), findsOneWidget);
    expect(find.text('12 Lagu'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgetsWithMocks('LibraryScreen creates a playlist dialog flow', (WidgetTester tester) async {
    final fakePlaylist = FakePlaylistService();

    await tester.pumpWidget(
      createTestableWidget(
        child: const LibraryScreen(),
        playlist: fakePlaylist,
      ),
    );

    await tester.pumpAndSettle();

    // Tap FloatingActionButton to create playlist
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(); // Open dialog

    // Verify Dialog rendered
    expect(find.text('Buat Playlist Baru'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter name and submit
    await tester.enterText(find.byType(TextField), 'My Summer Playlist');
    await tester.tap(find.text('Buat'));
    await tester.pumpAndSettle();

    // Verify dialog closed and playlist service was called to add the new playlist
    expect(find.text('Buat Playlist Baru'), findsNothing);
    expect(fakePlaylist.playlists.any((p) => p.name == 'My Summer Playlist'), isTrue);
  });

  testWidgetsWithMocks('LibraryScreen favorites tab displays correct items', (WidgetTester tester) async {
    final fakeFavorites = FakeFavoritesService();
    
    await tester.pumpWidget(
      createTestableWidget(
        child: const LibraryScreen(),
        favorites: fakeFavorites,
      ),
    );

    await tester.pumpAndSettle();

    // Switch to Favorit Tab
    await tester.tap(find.text('Favorit'));
    await tester.pumpAndSettle();

    // Verify items in Favorites
    expect(find.text('Lagu Favorit 1'), findsOneWidget);
    expect(find.text('Artis Populer'), findsOneWidget);
  });

  testWidgetsWithMocks('LibraryScreen history tab displays items and clear button works', (WidgetTester tester) async {
    final fakeHistory = FakeHistoryService();

    await tester.pumpWidget(
      createTestableWidget(
        child: const LibraryScreen(),
        history: fakeHistory,
      ),
    );

    await tester.pumpAndSettle();

    // Switch to Riwayat Tab
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    // Verify items in History
    expect(find.text('Riwayat Lagu 1'), findsOneWidget);
    expect(find.text('Artis Lawas'), findsOneWidget);
    expect(find.text('Terakhir Diputar'), findsOneWidget);

    // Tap clear button
    await tester.tap(find.text('Bersihkan'));
    await tester.pumpAndSettle();

    // Verify history list cleared and shows empty state placeholder
    expect(fakeHistory.history, isEmpty);
    expect(find.text('Belum ada riwayat'), findsOneWidget);
  });
}

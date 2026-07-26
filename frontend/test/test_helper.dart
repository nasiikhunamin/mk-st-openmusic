import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/services/auth_service.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/services/playlist_service.dart';
import 'package:openmusic_frontend/services/favorites_service.dart';
import 'package:openmusic_frontend/services/history_service.dart';
import 'package:openmusic_frontend/models/user.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/models/playlist.dart';
import 'package:dio/dio.dart';

// Custom testWidgets wrapper that automatically handles NetworkImage mocking and cleans up before invariants check
void testWidgetsWithMocks(
  String description,
  Future<void> Function(WidgetTester tester) callback, {
  bool skip = false,
}) {
  testWidgets(description, (WidgetTester tester) async {
    debugNetworkImageHttpClientProvider = () => FakeHttpClient();
    try {
      await callback(tester);
    } finally {
      debugNetworkImageHttpClientProvider = null;
      print("TEST DEBUG: debugNetworkImageHttpClientProvider reset to null. Current value: $debugNetworkImageHttpClientProvider");
    }
  }, skip: skip);
}

class FakeHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print("TEST DEBUG: FakeHttpClient called for: ${invocation.memberName}");
    if (invocation.memberName == #getUrl) {
      return Future.value(FakeHttpClientRequest());
    }
    if (invocation.memberName == #autoUncompress) {
      return true;
    }
    return null;
  }
}

class FakeHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print("TEST DEBUG: FakeHttpClientRequest called for: ${invocation.memberName}");
    if (invocation.memberName == #close) {
      return Future.value(FakeHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return FakeHttpHeaders();
    }
    return null;
  }
}

class FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print("TEST DEBUG: FakeHttpHeaders called for: ${invocation.memberName}");
    return null;
  }
}

class FakeHttpClientResponse implements HttpClientResponse {
  // Transparent 1x1 png image bytes
  static final List<int> _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    print("TEST DEBUG: FakeHttpClientResponse called for: ${invocation.memberName}");
    if (invocation.memberName == #listen) {
      final onData = invocation.positionalArguments[0] as void Function(List<int>);
      final onError = invocation.namedArguments[#onError] as void Function(Object, StackTrace)?;
      final onDone = invocation.namedArguments[#onDone] as void Function()?;
      final cancelOnError = invocation.namedArguments[#cancelOnError] as bool?;
      
      return Stream<List<int>>.fromIterable([_transparentImage]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }
    return null;
  }
}

class FakeApiClient implements ApiClient {
  @override
  final Dio dio = Dio();

  @override
  String baseUrl = 'http://test-api';

  @override
  String? accessToken;

  FakeApiClient() {
    dio.options.baseUrl = baseUrl;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/api/tracks')) {
          final q = options.queryParameters['q'] ?? '';
          final mockTracks = [
            {
              'id': 't_mock_1',
              'title': 'Mock Track 1 ($q)',
              'artist': 'Mock Artist',
              'album': 'Mock Album',
              'cover_url': '',
              'audio_url': 'http://test-audio.mp3',
              'duration': 180,
              'source': 'jamendo'
            }
          ];
          handler.resolve(Response(
            requestOptions: options,
            data: {
              'data': mockTracks,
              'meta': {'total': 1, 'page': 1, 'page_size': 20, 'total_pages': 1}
            },
            statusCode: 200,
          ));
        } else if (options.path.contains('/api/auth/me')) {
          handler.resolve(Response(
            requestOptions: options,
            data: {
              'id': 'u1',
              'username': 'TestUser',
              'email': 'test@example.com',
              'created_at': DateTime.now().toIso8601String()
            },
            statusCode: 200,
          ));
        } else {
          handler.resolve(Response(
            requestOptions: options,
            data: {
              'data': [],
              'meta': {'total': 0, 'page': 1, 'page_size': 20, 'total_pages': 0}
            },
            statusCode: 200,
          ));
        }
      },
    ));
  }

  @override
  void setBaseUrl(String url) {
    baseUrl = url;
  }

  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveRefreshToken(String rt) async {}
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  final ApiClient apiClient = FakeApiClient();

  bool _isLoggedIn = false;
  User? _currentUser;
  bool _isInitialized = true;
  String? _authError;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? get authError => _authError;

  void setLoggedIn(bool value, {User? user}) {
    _isLoggedIn = value;
    _currentUser = user;
    notifyListeners();
  }

  void setAuthError(String? error) {
    _authError = error;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> fetchUserProfile() async {
    _currentUser = User(
      id: 'u1',
      username: 'TestUser',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  Future<bool> login(String email, String password) async {
    if (email == 'test@example.com' && password == 'password123') {
      _isLoggedIn = true;
      _currentUser = User(
        id: 'u1',
        username: 'TestUser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );
      _authError = null;
      notifyListeners();
      return true;
    } else {
      _authError = 'Invalid email or password';
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> register(String username, String email, String password) async {
    _isLoggedIn = true;
    _currentUser = User(
      id: 'u1',
      username: username,
      email: email,
      createdAt: DateTime.now(),
    );
    _authError = null;
    notifyListeners();
    return true;
  }

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}

class FakePlayerService extends ChangeNotifier implements PlayerService {
  @override
  final ApiClient apiClient = FakeApiClient();

  @override
  Track? currentTrack;

  @override
  List<Track> queue = [];

  @override
  bool isPlaying = false;

  @override
  Duration position = Duration.zero;

  @override
  Duration duration = Duration.zero;

  @override
  Duration bufferedPosition = Duration.zero;

  @override
  Future<void> playTrack(Track track, {List<Track> newQueue = const []}) async {
    currentTrack = track;
    isPlaying = true;
    if (newQueue.isNotEmpty) {
      queue = newQueue;
    }
    notifyListeners();
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration position) async {
    this.position = position;
    notifyListeners();
  }

  @override
  Future<void> next() async {
    notifyListeners();
  }

  @override
  Future<void> previous() async {
    notifyListeners();
  }

  @override
  void setQueue(List<Track> newQueue) {
    queue = newQueue;
    notifyListeners();
  }
}

class FakePlaylistService extends ChangeNotifier implements PlaylistService {
  @override
  final ApiClient apiClient = FakeApiClient();

  @override
  List<Playlist> playlists = [];

  @override
  bool isLoading = false;

  @override
  Future<void> fetchPlaylists() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    playlists = [
      Playlist(
        id: 'p1',
        name: 'Chill Beats',
        trackCount: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Playlist(
        id: 'p2',
        name: 'Rock Classics',
        trackCount: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<Playlist?> fetchPlaylistDetail(String id) async {
    return Playlist(
      id: id,
      name: 'Sample Playlist',
      trackCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> createPlaylist(String name) async {
    playlists.add(Playlist(
      id: 'p${playlists.length + 1}',
      name: name,
      trackCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    notifyListeners();
    return true;
  }

  @override
  Future<bool> renamePlaylist(String id, String newName) async {
    final idx = playlists.indexWhere((p) => p.id == id);
    if (idx != -1) {
      playlists[idx] = Playlist(
        id: id,
        name: newName,
        trackCount: playlists[idx].trackCount,
        createdAt: playlists[idx].createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  Future<bool> deletePlaylist(String id) async {
    playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    return true;
  }

  @override
  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    return true;
  }
}

class FakeFavoritesService extends ChangeNotifier implements FavoritesService {
  @override
  final ApiClient apiClient = FakeApiClient();

  @override
  List<Track> favorites = [];

  @override
  bool isLoading = false;

  @override
  Future<void> fetchFavorites() async {
    isLoading = true;
    notifyListeners();
    favorites = [
      Track(
        id: 't1',
        title: 'Lagu Favorit 1',
        artist: 'Artis Populer',
        duration: 180,
        coverUrl: '',
        source: 'jamendo',
      ),
    ];
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<bool> addFavorite(Track track) async {
    favorites.add(track);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> removeFavorite(String trackId) async {
    favorites.removeWhere((t) => t.id == trackId);
    notifyListeners();
    return true;
  }

  @override
  bool isFavorite(String trackId) {
    return favorites.any((t) => t.id == trackId);
  }
}

class FakeHistoryService extends ChangeNotifier implements HistoryService {
  @override
  final ApiClient apiClient = FakeApiClient();

  @override
  List<Track> history = [];

  @override
  bool isLoading = false;

  @override
  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners();
    history = [
      Track(
        id: 'h1',
        title: 'Riwayat Lagu 1',
        artist: 'Artis Lawas',
        duration: 200,
        coverUrl: '',
        source: 'jamendo',
      ),
    ];
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<bool> clearHistory() async {
    history.clear();
    notifyListeners();
    return true;
  }
}

Widget createTestableWidget({
  required Widget child,
  FakeAuthService? auth,
  FakePlayerService? player,
  FakePlaylistService? playlist,
  FakeFavoritesService? favorites,
  FakeHistoryService? history,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: FakeApiClient()),
      ChangeNotifierProvider<AuthService>.value(value: auth ?? FakeAuthService()),
      ChangeNotifierProvider<PlayerService>.value(value: player ?? FakePlayerService()),
      ChangeNotifierProvider<PlaylistService>.value(value: playlist ?? FakePlaylistService()),
      ChangeNotifierProvider<FavoritesService>.value(value: favorites ?? FakeFavoritesService()),
      ChangeNotifierProvider<HistoryService>.value(value: history ?? FakeHistoryService()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

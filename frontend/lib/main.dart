import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/services/auth_service.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/services/playlist_service.dart';
import 'package:openmusic_frontend/services/favorites_service.dart';
import 'package:openmusic_frontend/services/history_service.dart';
import 'package:openmusic_frontend/screens/login_screen.dart';
import 'package:openmusic_frontend/screens/home_wrapper.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(apiClient: apiClient)..initialize(),
        ),
        ChangeNotifierProvider<PlayerService>(
          create: (_) => PlayerService(apiClient: apiClient),
        ),
        ChangeNotifierProvider<PlaylistService>(
          create: (_) => PlaylistService(apiClient: apiClient),
        ),
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService(apiClient: apiClient),
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService(apiClient: apiClient),
        ),
      ],
      child: const OpenMusicApp(),
    ),
  );
}

class OpenMusicApp extends StatelessWidget {
  const OpenMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenMusic',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.tealAccent),
        ),
      );
    }

    return authService.isLoggedIn ? const HomeWrapper() : const LoginScreen();
  }
}

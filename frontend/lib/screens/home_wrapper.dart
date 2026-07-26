import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/screens/home_screen.dart';
import 'package:openmusic_frontend/screens/search_screen.dart';
import 'package:openmusic_frontend/screens/library_screen.dart';
import 'package:openmusic_frontend/screens/profile_screen.dart';
import 'package:openmusic_frontend/widgets/mini_player.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onSearchTap: () {
        setState(() {
          _selectedIndex = 1; // Switch to Search tab
        });
      }),
      const SearchScreen(),
      const LibraryScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final hasActiveTrack = playerService.currentTrack != null;

    return Scaffold(
      body: Stack(
        children: [
          // Keep screens alive while switching tabs
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          
          // MiniPlayer floating overlay
          if (hasActiveTrack)
            Positioned(
              left: 8,
              right: 8,
              bottom: kBottomNavigationBarHeight + 8, // float above BottomNavigationBar
              child: const MiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppTheme.tealAccent),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search, color: AppTheme.tealAccent),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music, color: AppTheme.tealAccent),
            label: 'Koleksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: AppTheme.tealAccent),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

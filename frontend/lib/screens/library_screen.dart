import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/playlist_service.dart';
import 'package:openmusic_frontend/services/favorites_service.dart';
import 'package:openmusic_frontend/services/history_service.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/screens/playlist_detail_screen.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initial fetch of library data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistService>(context, listen: false).fetchPlaylists();
      Provider.of<FavoritesService>(context, listen: false).fetchFavorites();
      Provider.of<HistoryService>(context, listen: false).fetchHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Buat Playlist Baru'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Playlist',
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.tealAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final success = await Provider.of<PlaylistService>(context, listen: false).createPlaylist(name);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Playlist berhasil dibuat' : 'Gagal membuat playlist'),
                        backgroundColor: success ? AppTheme.tealAccent : AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Buat', style: TextStyle(color: AppTheme.tealAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Koleksi Musik', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.tealAccent,
          labelColor: AppTheme.tealAccent,
          unselectedLabelColor: AppTheme.mutedText,
          tabs: const [
            Tab(text: 'Playlist'),
            Tab(text: 'Favorit'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaylistsTab(),
          _buildFavoritesTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<double>(
        valueListenable: ValueNotifier(0.0), // stub
        builder: (context, value, child) {
          return _tabController.index == 0
              ? FloatingActionButton(
                  onPressed: _showCreatePlaylistDialog,
                  backgroundColor: AppTheme.tealAccent,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.add),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    return Consumer<PlaylistService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final playlists = service.playlists;

        if (playlists.isEmpty) {
          return const Center(
            child: Text('Belum ada playlist. Klik + untuk membuat.', style: TextStyle(color: AppTheme.mutedText)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.playlist_play, color: AppTheme.tealAccent, size: 28),
              ),
              title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${playlist.trackCount} Lagu', style: const TextStyle(color: AppTheme.mutedText)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedText),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(playlistId: playlist.id, playlistName: playlist.name),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    final playerService = Provider.of<PlayerService>(context, listen: false);

    return Consumer<FavoritesService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final favorites = service.favorites;

        if (favorites.isEmpty) {
          return const Center(
            child: Text('Belum ada lagu favorit.', style: TextStyle(color: AppTheme.mutedText)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final track = favorites[index];
            return Dismissible(
              key: Key('fav-${track.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppTheme.error,
                child: const Icon(Icons.delete, color: Colors.black),
              ),
              onDismissed: (_) async {
                await service.removeFavorite(track.id);
              },
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: track.coverUrl != null && track.coverUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(track.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppTheme.surface,
                  ),
                  child: track.coverUrl == null || track.coverUrl!.isEmpty
                      ? const Icon(Icons.music_note, color: AppTheme.mutedText)
                      : null,
                ),
                title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(track.artist, style: const TextStyle(color: AppTheme.mutedText)),
                onTap: () {
                  playerService.playTrack(track, newQueue: favorites);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final playerService = Provider.of<PlayerService>(context, listen: false);

    return Consumer<HistoryService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
        }

        final history = service.history;

        if (history.isEmpty) {
          return const Center(
            child: Text('Belum ada riwayat musik terputar.', style: TextStyle(color: AppTheme.mutedText)),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar putar terakhir', style: TextStyle(color: AppTheme.mutedText)),
                  TextButton.icon(
                    onPressed: () async {
                      await service.clearHistory();
                    },
                    icon: const Icon(Icons.clear_all, size: 20, color: AppTheme.error),
                    label: const Text('Bersihkan', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final track = history[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: track.coverUrl != null && track.coverUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(track.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppTheme.surface,
                      ),
                      child: track.coverUrl == null || track.coverUrl!.isEmpty
                          ? const Icon(Icons.music_note, color: AppTheme.mutedText)
                          : null,
                    ),
                    title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(track.artist, style: const TextStyle(color: AppTheme.mutedText)),
                    onTap: () {
                      playerService.playTrack(track, newQueue: history);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

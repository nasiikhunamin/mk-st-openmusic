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
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update floating action button visibility
    });
    
    // Initial fetch of library data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    Provider.of<PlaylistService>(context, listen: false).fetchPlaylists();
    Provider.of<FavoritesService>(context, listen: false).fetchFavorites();
    Provider.of<HistoryService>(context, listen: false).fetchHistory();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: const Text('Buat Playlist Baru', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nama Playlist',
              labelStyle: const TextStyle(color: AppTheme.mutedText),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.tealAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final success = await Provider.of<PlaylistService>(context, listen: false).createPlaylist(name);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Playlist "$name" berhasil dibuat' : 'Gagal membuat playlist'),
                        backgroundColor: success ? AppTheme.tealAccent : AppTheme.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Buat', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showRenamePlaylistDialog(String playlistId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: const Text('Ubah Nama Playlist', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nama Baru',
              labelStyle: const TextStyle(color: AppTheme.mutedText),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.tealAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  final success = await Provider.of<PlaylistService>(context, listen: false).renamePlaylist(playlistId, newName);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Nama playlist diubah menjadi "$newName"' : 'Gagal mengubah nama playlist'),
                        backgroundColor: success ? AppTheme.tealAccent : AppTheme.error,
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistConfirm(String playlistId, String playlistName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: const Text('Hapus Playlist?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(
            'Apakah Anda yakin ingin menghapus playlist "$playlistName"? Lagu di dalamnya tidak akan terhapus dari library.',
            style: const TextStyle(color: AppTheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<PlaylistService>(context, listen: false).deletePlaylist(playlistId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Playlist "$playlistName" berhasil dihapus' : 'Gagal menghapus playlist'),
                      backgroundColor: success ? AppTheme.tealAccent : AppTheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.black,
              ),
              child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(
          'Koleksi Musik',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.tealAccent,
          indicatorWeight: 3,
          labelColor: AppTheme.tealAccent,
          unselectedLabelColor: AppTheme.mutedText,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
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
      floatingActionButton: _tabController.index == 0
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tealAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showCreatePlaylistDialog,
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: Colors.black,
                elevation: 0,
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add, size: 64, color: AppTheme.mutedText.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada playlist',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Klik tombol + untuk membuat playlist pertama Anda',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => service.fetchPlaylists(),
          color: AppTheme.tealAccent,
          backgroundColor: AppTheme.surface,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.playlist_play, color: Colors.white, size: 28),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${playlist.trackCount} Lagu',
                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.mutedText),
                      color: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenamePlaylistDialog(playlist.id, playlist.name);
                        } else if (value == 'delete') {
                          _showDeletePlaylistConfirm(playlist.id, playlist.name);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                              SizedBox(width: 10),
                              Text('Ubah Nama', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                              SizedBox(width: 10),
                              Text('Hapus', style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlistId: playlist.id, playlistName: playlist.name),
                        ),
                      ).then((_) => service.fetchPlaylists()); // Refresh on back
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final service = Provider.of<FavoritesService>(context);

    if (service.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
    }

    final favorites = service.favorites;

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.mutedText.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada favorit',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sentuh tombol hati di pemutar musik untuk menambahkan',
              style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => service.fetchFavorites(),
      color: AppTheme.tealAccent,
      backgroundColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final track = favorites[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.black26,
                    child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                        ? Image.network(
                            track.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppTheme.primary),
                          )
                        : const Icon(Icons.music_note, color: AppTheme.primary),
                  ),
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artist,
                  style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
                  onPressed: () async {
                    final success = await service.removeFavorite(track.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${track.title}" dihapus dari favorit'),
                          backgroundColor: AppTheme.surface,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                onTap: () {
                  playerService.playTrack(track, newQueue: favorites);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final service = Provider.of<HistoryService>(context);

    if (service.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
    }

    final history = service.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.mutedText.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Musik yang Anda putar akan tampil di sini',
              style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => service.fetchHistory(),
      color: AppTheme.tealAccent,
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Terakhir Diputar',
                  style: TextStyle(color: AppTheme.mutedText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final success = await service.clearHistory();
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Riwayat pemutaran dibersihkan'),
                          backgroundColor: AppTheme.surface,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.clear_all, size: 18, color: AppTheme.error),
                  label: const Text('Bersihkan', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final track = history[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.black26,
                          child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                              ? Image.network(
                                  track.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: AppTheme.primary),
                                )
                              : const Icon(Icons.music_note, color: AppTheme.primary),
                        ),
                      ),
                      title: Text(
                        track.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist,
                        style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.play_arrow_outlined, color: AppTheme.tealAccent, size: 24),
                      onTap: () {
                        playerService.playTrack(track, newQueue: history);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

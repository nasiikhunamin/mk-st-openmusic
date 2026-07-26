import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/models/playlist.dart';
import 'package:openmusic_frontend/services/playlist_service.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
    });

    final service = Provider.of<PlaylistService>(context, listen: false);
    final detail = await service.fetchPlaylistDetail(widget.playlistId);

    if (mounted) {
      setState(() {
        _playlist = detail;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Playlist'),
        content: Text('Apakah Anda yakin ingin menghapus playlist "${widget.playlistName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<PlaylistService>(context, listen: false).deletePlaylist(widget.playlistId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist berhasil dihapus'), backgroundColor: AppTheme.tealAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final playlistService = Provider.of<PlaylistService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _deletePlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
          : _playlist == null
              ? const Center(
                  child: Text('Gagal memuat detail playlist.', style: TextStyle(color: AppTheme.mutedText)),
                )
              : _playlist!.tracks.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada lagu di playlist ini.\nCari lagu lalu tambahkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedText),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _playlist!.tracks.length,
                      itemBuilder: (context, index) {
                        final track = _playlist!.tracks[index];
                        return Dismissible(
                          key: Key('playlist-track-${track.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppTheme.error,
                            child: const Icon(Icons.delete, color: Colors.black),
                          ),
                          onDismissed: (_) async {
                            final success = await playlistService.removeTrackFromPlaylist(widget.playlistId, track.id);
                            if (success) {
                              setState(() {
                                _playlist!.tracks.removeAt(index);
                              });
                            }
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
                              playerService.playTrack(track, newQueue: _playlist!.tracks);
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

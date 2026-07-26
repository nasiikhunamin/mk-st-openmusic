import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/playlist_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final Track track;
  const AddToPlaylistDialog({super.key, required this.track});

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final _newPlaylistController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    // Fetch playlists when dialog opens
    Provider.of<PlaylistService>(context, listen: false).fetchPlaylists();
  }

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _createAndAddPlaylist() async {
    final name = _newPlaylistController.text.trim();
    if (name.isEmpty) return;

    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    final success = await playlistService.createPlaylist(name);
    
    if (success && mounted) {
      // Find the newly created playlist (usually the last or match by name)
      final newPlaylist = playlistService.playlists.firstWhere((p) => p.name == name);
      final added = await playlistService.addTrackToPlaylist(newPlaylist.id, widget.track);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(added ? 'Lagu ditambahkan ke $name' : 'Gagal menambahkan lagu'),
            backgroundColor: added ? AppTheme.tealAccent : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistService = Provider.of<PlaylistService>(context);
    final playlists = playlistService.playlists;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        _isCreatingNew ? 'Buat Playlist Baru' : 'Tambah ke Playlist',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: _isCreatingNew
          ? TextField(
              controller: _newPlaylistController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Playlist',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.tealAccent),
                ),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 250,
              child: playlistService.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
                  : playlists.isEmpty
                      ? const Center(
                          child: Text(
                            'Anda belum memiliki playlist.',
                            style: TextStyle(color: AppTheme.mutedText),
                          ),
                        )
                      : ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return ListTile(
                              leading: const Icon(Icons.playlist_play, color: AppTheme.tealAccent),
                              title: Text(playlist.name),
                              subtitle: Text('${playlist.trackCount} Lagu'),
                              onTap: () async {
                                final success = await playlistService.addTrackToPlaylist(playlist.id, widget.track);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'Berhasil ditambahkan ke ${playlist.name}'
                                          : 'Lagu sudah ada di playlist ini'),
                                      backgroundColor: success ? AppTheme.tealAccent : AppTheme.error,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isCreatingNew) {
              setState(() {
                _isCreatingNew = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
        ),
        if (!_isCreatingNew)
          TextButton(
            onPressed: () {
              setState(() {
                _isCreatingNew = true;
              });
            },
            child: const Text('Buat Baru', style: TextStyle(color: AppTheme.tealAccent)),
          )
        else
          TextButton(
            onPressed: _createAndAddPlaylist,
            child: const Text('Simpan & Tambah', style: TextStyle(color: AppTheme.tealAccent)),
          ),
      ],
    );
  }
}

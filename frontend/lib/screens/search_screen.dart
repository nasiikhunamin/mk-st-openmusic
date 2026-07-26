import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/services/favorites_service.dart';
import 'package:openmusic_frontend/widgets/add_to_playlist_dialog.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  List<Track> _tracks = [];
  bool _isLoading = false;
  bool _isLoadMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadMore && _currentPage < _totalPages) {
        _searchTracks(loadNextPage: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        _currentPage = 1;
        _tracks.clear();
        _searchTracks();
      } else {
        setState(() {
          _tracks.clear();
        });
      }
    });
  }

  Future<void> _searchTracks({bool loadNextPage = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      if (loadNextPage) {
        _isLoadMore = true;
      } else {
        _isLoading = true;
      }
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final targetPage = loadNextPage ? _currentPage + 1 : 1;

    try {
      final response = await apiClient.dio.get(
        '/api/tracks',
        queryParameters: {
          'q': query,
          'page': targetPage,
          'pageSize': _pageSize,
        },
      );

      if (response.statusCode == 200) {
        final dataList = response.data['data'] as List;
        final meta = response.data['meta'];
        _totalPages = meta['total_pages'] as int;
        _currentPage = meta['page'] as int;

        final newTracks = dataList.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
        setState(() {
          if (loadNextPage) {
            _tracks.addAll(newTracks);
          } else {
            _tracks = newTracks;
          }
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal melakukan pencarian musik.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadMore = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showTrackOptions(BuildContext context, Track track) {
    final favoritesService = Provider.of<FavoritesService>(context, listen: false);
    final isFav = favoritesService.isFavorite(track.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                title: Text(isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
                onTap: () async {
                  Navigator.pop(context);
                  if (isFav) {
                    await favoritesService.removeFavorite(track.id);
                  } else {
                    await favoritesService.addFavorite(track);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Tambah ke Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddToPlaylistDialog(track: track),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cari Musik',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari lagu, artis, atau album...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.mutedText),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.mutedText),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tracks List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
                    : _tracks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note_outlined, size: 64, color: AppTheme.mutedText.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Cari jutaan lagu di OpenMusic',
                                  style: TextStyle(color: AppTheme.mutedText),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _tracks.length + (_isLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _tracks.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.tealAccent)),
                                );
                              }

                              final track = _tracks[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
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
                                title: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${track.artist} • ${_formatDuration(track.duration ?? 0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.mutedText),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert, color: AppTheme.mutedText),
                                  onPressed: () => _showTrackOptions(context, track),
                                ),
                                onTap: () {
                                  playerService.playTrack(track, newQueue: _tracks);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

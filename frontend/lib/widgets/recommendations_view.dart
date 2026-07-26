import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class RecommendationsView extends StatefulWidget {
  final String trackId;
  const RecommendationsView({super.key, required this.trackId});

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  List<Track> _similarTracks = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  @override
  void didUpdateWidget(covariant RecommendationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      _fetchRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _similarTracks.clear();
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final response = await apiClient.dio.get(
        '/api/tracks/${widget.trackId}/similar',
        queryParameters: {'limit': 10},
      );
      if (response.statusCode == 200) {
        final dataList = response.data['data'] as List;
        setState(() {
          _similarTracks = dataList.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Rekomendasi tidak tersedia saat ini.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.mutedText),
        ),
      );
    }

    if (_similarTracks.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada rekomendasi lagu serupa.',
          style: TextStyle(color: AppTheme.mutedText),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _similarTracks.length,
      itemBuilder: (context, index) {
        final track = _similarTracks[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '${track.artist} • ${_formatDuration(track.duration ?? 0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
          ),
          trailing: const Icon(Icons.play_arrow_outlined, color: AppTheme.tealAccent),
          onTap: () {
            playerService.playTrack(track, newQueue: _similarTracks);
          },
        );
      },
    );
  }
}

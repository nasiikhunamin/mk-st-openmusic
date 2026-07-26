import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class LyricsView extends StatefulWidget {
  final String trackId;
  const LyricsView({super.key, required this.trackId});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  String? _plainLyrics;
  String? _syncedLyrics;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      _fetchLyrics();
    }
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _plainLyrics = null;
      _syncedLyrics = null;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final response = await apiClient.dio.get('/api/tracks/${widget.trackId}/lyrics');
      if (response.statusCode == 200) {
        setState(() {
          _plainLyrics = response.data['plain_lyrics'] as String?;
          _syncedLyrics = response.data['synced_lyrics'] as String?;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lirik tidak tersedia.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final displayText = _plainLyrics ?? _syncedLyrics;

    if (displayText == null || displayText.trim().isEmpty) {
      return const Center(
        child: Text(
          'Lirik tidak tersedia.',
          style: TextStyle(color: AppTheme.mutedText),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              height: 1.8,
              color: Colors.white.withOpacity(0.9),
            ),
      ),
    );
  }
}

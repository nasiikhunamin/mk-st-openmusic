import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/services/favorites_service.dart';
import 'package:openmusic_frontend/widgets/lyrics_view.dart';
import 'package:openmusic_frontend/widgets/recommendations_view.dart';
import 'package:openmusic_frontend/widgets/add_to_playlist_dialog.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final track = playerService.currentTrack;

    if (track == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada lagu yang sedang diputar')),
      );
    }

    final favoritesService = Provider.of<FavoritesService>(context);
    final isFav = favoritesService.isFavorite(track.id);
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'SEDANG DIPUTAR',
            style: textTheme.labelLarge?.copyWith(letterSpacing: 2.0),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddToPlaylistDialog(track: track),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Player top section (album art + controls)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Album Cover with Glow Effect
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryContainer.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: track.coverUrl != null && track.coverUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(track.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppTheme.surface,
                      ),
                      child: track.coverUrl == null || track.coverUrl!.isEmpty
                          ? const Icon(Icons.music_note, size: 80, color: AppTheme.mutedText)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Title, Artist, & Favorite Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.mutedText, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                            size: 28,
                          ),
                          onPressed: () async {
                            if (isFav) {
                              await favoritesService.removeFavorite(track.id);
                            } else {
                              await favoritesService.addFavorite(track);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
                    ProgressBar(
                      progress: playerService.position,
                      buffered: playerService.bufferedPosition,
                      total: playerService.duration,
                      progressBarColor: AppTheme.tealAccent,
                      baseBarColor: Colors.white10,
                      bufferedBarColor: Colors.white24,
                      thumbColor: AppTheme.tealAccent,
                      barHeight: 4.0,
                      thumbRadius: 6.0,
                      timeLabelTextStyle: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                      onSeek: (duration) {
                        playerService.seek(duration);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: AppTheme.mutedText),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
                          onPressed: () {
                            playerService.previous();
                          },
                        ),
                        // Circular Play Button with gradient glow
                        GestureDetector(
                          onTap: () {
                            if (playerService.isPlaying) {
                              playerService.pause();
                            } else {
                              playerService.play();
                            }
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: Icon(
                              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
                          onPressed: () {
                            playerService.next();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat, color: AppTheme.mutedText),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TabBar section
              const TabBar(
                indicatorColor: AppTheme.tealAccent,
                labelColor: AppTheme.tealAccent,
                unselectedLabelColor: AppTheme.mutedText,
                tabs: [
                  Tab(text: 'Lirik'),
                  Tab(text: 'Rekomendasi'),
                ],
              ),

              // TabBarView section
              Expanded(
                child: Container(
                  color: Colors.black12,
                  child: TabBarView(
                    children: [
                      LyricsView(trackId: track.id),
                      RecommendationsView(trackId: track.id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

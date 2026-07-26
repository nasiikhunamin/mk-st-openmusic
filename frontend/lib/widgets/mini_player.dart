import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/screens/player_screen.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final track = playerService.currentTrack;

    if (track == null) return const SizedBox.shrink();

    // Calculate progress fraction
    double progress = 0.0;
    if (playerService.duration.inMilliseconds > 0) {
      progress = playerService.position.inMilliseconds / playerService.duration.inMilliseconds;
    }
    progress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      // Album Cover Art
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: track.coverUrl != null && track.coverUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(track.coverUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.black26,
                        ),
                        child: track.coverUrl == null || track.coverUrl!.isEmpty
                            ? const Icon(Icons.music_note, color: AppTheme.mutedText)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // Song info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      IconButton(
                        icon: Icon(
                          playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (playerService.isPlaying) {
                            playerService.pause();
                          } else {
                            playerService.play();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          playerService.next();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Linear Progress Line
              SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tealAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

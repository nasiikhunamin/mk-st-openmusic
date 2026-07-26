class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;
  final String source;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    this.audioUrl,
    this.duration,
    required this.source,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      coverUrl: json['cover_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      duration: json['duration'] as int?,
      source: json['source'] as String? ?? 'jamendo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'cover_url': coverUrl,
      'audio_url': audioUrl,
      'duration': duration,
      'source': source,
    };
  }
}

class TrackLyrics {
  final String? plainLyrics;
  final String? syncedLyrics;

  TrackLyrics({this.plainLyrics, this.syncedLyrics});

  factory TrackLyrics.fromJson(Map<String, dynamic> json) {
    return TrackLyrics(
      plainLyrics: json['plain_lyrics'] as String?,
      syncedLyrics: json['synced_lyrics'] as String?,
    );
  }
}

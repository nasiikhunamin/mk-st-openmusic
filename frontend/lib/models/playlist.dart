import 'package:openmusic_frontend/models/track.dart';

class Playlist {
  final String id;
  final String name;
  final int trackCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.createdAt,
    required this.updatedAt,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    var tracksList = json['tracks'] as List?;
    List<Track> parsedTracks = [];
    if (tracksList != null) {
      parsedTracks = tracksList.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
    }

    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      trackCount: json['track_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tracks: parsedTracks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'track_count': trackCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:openmusic_frontend/models/playlist.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';

class PlaylistService extends ChangeNotifier {
  final ApiClient apiClient;
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  PlaylistService({required this.apiClient});

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;

  Future<void> fetchPlaylists() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/api/playlists');
      if (response.statusCode == 200) {
        final dataList = response.data['data'] as List;
        _playlists = dataList.map((p) => Playlist.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> fetchPlaylistDetail(String id) async {
    try {
      final response = await apiClient.dio.get('/api/playlists/$id');
      if (response.statusCode == 200) {
        return Playlist.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createPlaylist(String name) async {
    try {
      final response = await apiClient.dio.post(
        '/api/playlists',
        data: {'name': name},
      );
      if (response.statusCode == 201) {
        await fetchPlaylists();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> renamePlaylist(String id, String newName) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/playlists/$id',
        data: {'name': newName},
      );
      if (response.statusCode == 200) {
        await fetchPlaylists();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deletePlaylist(String id) async {
    try {
      final response = await apiClient.dio.delete('/api/playlists/$id');
      if (response.statusCode == 204) {
        _playlists.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    try {
      final response = await apiClient.dio.post(
        '/api/playlists/$playlistId/tracks',
        data: {
          'track_id': track.id,
          'track_metadata': track.toJson(),
        },
      );
      if (response.statusCode == 204) {
        await fetchPlaylists();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final response = await apiClient.dio.delete(
        '/api/playlists/$playlistId/tracks/$trackId',
      );
      if (response.statusCode == 204) {
        await fetchPlaylists();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

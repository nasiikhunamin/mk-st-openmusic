import 'package:flutter/material.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';

class FavoritesService extends ChangeNotifier {
  final ApiClient apiClient;
  List<Track> _favorites = [];
  bool _isLoading = false;

  FavoritesService({required this.apiClient});

  List<Track> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/api/favorites');
      if (response.statusCode == 200) {
        final dataList = response.data['data'] as List;
        _favorites = dataList.map((item) {
          // In the database model, the favorites return structure contains:
          // id, user_id, track_id, track_metadata, added_at
          final metadata = item['track_metadata'] as Map<String, dynamic>;
          return Track.fromJson(metadata);
        }).toList();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFavorite(Track track) async {
    try {
      final response = await apiClient.dio.post(
        '/api/favorites',
        data: {
          'track_id': track.id,
          'track_metadata': track.toJson(),
        },
      );
      if (response.statusCode == 201) {
        _favorites.add(track);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeFavorite(String trackId) async {
    try {
      final response = await apiClient.dio.delete('/api/favorites/$trackId');
      if (response.statusCode == 204) {
        _favorites.removeWhere((t) => t.id == trackId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool isFavorite(String trackId) {
    return _favorites.any((t) => t.id == trackId);
  }
}

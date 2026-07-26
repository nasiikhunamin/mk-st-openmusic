import 'package:flutter/material.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';

class HistoryService extends ChangeNotifier {
  final ApiClient apiClient;
  List<Track> _history = [];
  bool _isLoading = false;

  HistoryService({required this.apiClient});

  List<Track> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.get('/api/history');
      if (response.statusCode == 200) {
        final dataList = response.data['data'] as List;
        _history = dataList.map((item) {
          final trackJson = item['track'] as Map<String, dynamic>;
          return Track.fromJson(trackJson);
        }).toList();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> clearHistory() async {
    try {
      final response = await apiClient.dio.delete('/api/history');
      if (response.statusCode == 204) {
        _history.clear();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

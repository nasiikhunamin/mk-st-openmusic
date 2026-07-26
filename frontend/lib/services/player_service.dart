import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';

class PlayerService extends ChangeNotifier {
  final ApiClient apiClient;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = -1;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  PlayerService({required this.apiClient}) {
    // Listen to play/pause state changes
    _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // Listen to current audio position
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Listen to buffering state
    _audioPlayer.bufferedPositionStream.listen((buffered) {
      _bufferedPosition = buffered;
      notifyListeners();
    });

    // Listen to total duration
    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    // Listen to player state (completed track)
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  Track? get currentTrack => _currentTrack;
  List<Track> get queue => _queue;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;

  Future<void> playTrack(Track track, {List<Track> newQueue = const []}) async {
    _currentTrack = track;
    
    if (newQueue.isNotEmpty) {
      _queue = List.from(newQueue);
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
    } else {
      if (!_queue.any((t) => t.id == track.id)) {
        _queue.add(track);
      }
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
    }

    notifyListeners();

    try {
      // 1. Record play history in backend & fetch stream url (Jamendo audio_url is pre-provided or from stream endpoint)
      String? streamUrl = track.audioUrl;
      try {
        final response = await apiClient.dio.get('/api/tracks/${track.id}/stream');
        if (response.statusCode == 200) {
          streamUrl = response.data['audio_url'] as String?;
        }
      } catch (_) {
        // Fallback to local audioUrl if API fails
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception("Audio URL tidak ditemukan");
      }

      // 2. Set source and play
      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();
    } catch (e) {
      // Handle playback error
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> play() async {
    if (_currentTrack != null) {
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty || _currentIndex == -1) return;
    
    int nextIndex = _currentIndex + 1;
    if (nextIndex < _queue.length) {
      await playTrack(_queue[nextIndex]);
    } else {
      // End of queue or loop back
      await playTrack(_queue[0]);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty || _currentIndex == -1) return;

    int prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      await playTrack(_queue[prevIndex]);
    } else {
      // Go to last track
      await playTrack(_queue[_queue.length - 1]);
    }
  }

  void setQueue(List<Track> newQueue) {
    _queue = List.from(newQueue);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

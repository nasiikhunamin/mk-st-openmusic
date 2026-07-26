import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:openmusic_frontend/models/user.dart';
import 'package:openmusic_frontend/services/api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient apiClient;
  bool _isLoggedIn = false;
  User? _currentUser;
  bool _isInitialized = false;
  String? _authError;

  AuthService({required this.apiClient});

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  String? get authError => _authError;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final rt = await apiClient.getRefreshToken();
    if (rt != null) {
      try {
        // Attempt token rotation
        final freshDio = Dio();
        freshDio.options.baseUrl = apiClient.baseUrl;
        
        final response = await freshDio.post(
          '/api/auth/refresh',
          data: {'refresh_token': rt},
        );

        if (response.statusCode == 200) {
          final data = response.data;
          apiClient.accessToken = data['access_token'] as String;
          await apiClient.saveRefreshToken(data['refresh_token'] as String);

          // Get user profile
          await fetchUserProfile();
          _isLoggedIn = true;
        }
      } catch (_) {
        // Token invalid/expired
        await apiClient.clearTokens();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await apiClient.dio.get('/api/auth/me');
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    _authError = null;
    notifyListeners();

    try {
      final response = await apiClient.dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        apiClient.accessToken = data['access_token'] as String;
        await apiClient.saveRefreshToken(data['refresh_token'] as String);

        await fetchUserProfile();
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _authError = _parseError(e);
    } catch (e) {
      _authError = "Terjadi kesalahan sistem.";
    }
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _authError = null;
    notifyListeners();

    try {
      final response = await apiClient.dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        apiClient.accessToken = data['access_token'] as String;
        await apiClient.saveRefreshToken(data['refresh_token'] as String);

        await fetchUserProfile();
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _authError = _parseError(e);
    } catch (e) {
      _authError = "Terjadi kesalahan sistem.";
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final rt = await apiClient.getRefreshToken();
    if (rt != null) {
      try {
        // Fire and forget logout on backend
        await apiClient.dio.post('/api/auth/logout', data: {'refresh_token': rt});
      } catch (_) {}
    }
    await apiClient.clearTokens();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  String _parseError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        final errorObj = data['error'];
        if (errorObj is Map && errorObj.containsKey('message')) {
          return errorObj['message'] as String;
        }
      }
      return "Gagal melakukan proses (Status: ${e.response!.statusCode}).";
    }
    return "Tidak dapat terhubung ke server. Periksa koneksi Anda.";
  }
}

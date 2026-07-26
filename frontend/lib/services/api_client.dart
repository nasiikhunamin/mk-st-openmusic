import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _accessToken;
  String _baseUrl = 'http://10.0.2.2:8000';
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshQueue = [];

  ApiClient() : dio = Dio() {
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && _accessToken != null) {
            // Prevent infinite loop if refresh request fails with 401
            if (e.requestOptions.path == '/api/auth/refresh') {
              return handler.next(e);
            }

            final requestOptions = e.requestOptions;

            if (_isRefreshing) {
              _refreshQueue.add((newToken) {
                requestOptions.headers['Authorization'] = 'Bearer $newToken';
                dio.fetch(requestOptions).then(
                  (res) => handler.resolve(res),
                  onError: (err) => handler.reject(err),
                );
              });
              return;
            }

            _isRefreshing = true;
            try {
              final newTokens = await _refreshToken();
              if (newTokens != null) {
                _accessToken = newTokens['access_token'];
                requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
                
                for (var callback in _refreshQueue) {
                  callback(_accessToken!);
                }
                _refreshQueue.clear();

                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              }
            } catch (err) {
              _accessToken = null;
              await _secureStorage.delete(key: 'refresh_token');
              _refreshQueue.clear();
            } finally {
              _isRefreshing = false;
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;
  String? get accessToken => _accessToken;
  set accessToken(String? token) => _accessToken = token;

  Future<Map<String, String>?> _refreshToken() async {
    final rt = await _secureStorage.read(key: 'refresh_token');
    if (rt == null) return null;

    try {
      // Create separate Dio instance to avoid interceptor recursion
      final freshDio = Dio();
      freshDio.options.baseUrl = _baseUrl;
      
      final response = await freshDio.post(
        '/api/auth/refresh',
        data: {'refresh_token': rt},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final newAt = data['access_token'] as String;
        final newRt = data['refresh_token'] as String;
        await _secureStorage.write(key: 'refresh_token', value: newRt);
        return {'access_token': newAt, 'refresh_token': newRt};
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveRefreshToken(String rt) async {
    await _secureStorage.write(key: 'refresh_token', value: rt);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    await _secureStorage.delete(key: 'refresh_token');
  }
}

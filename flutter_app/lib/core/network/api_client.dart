import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  static ApiClient get instance => _instance ??= ApiClient._();
  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
  Future<Response> postForm(String path, {required FormData data}) =>
      _dio.post(path, data: data, options: Options(contentType: 'multipart/form-data'));

  Future<void> saveToken(String token) =>
      _storage.write(key: 'access_token', value: token);
  Future<void> clearToken() => _storage.delete(key: 'access_token');
  Future<String?> getToken() => _storage.read(key: 'access_token');
}


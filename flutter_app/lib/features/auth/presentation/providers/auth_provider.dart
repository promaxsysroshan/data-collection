import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/models.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isLoading, bool? isLoggedIn, UserModel? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _api = ApiClient.instance;
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final data = await _storage.read(key: 'user_data');
    final token = await _api.getToken();
    if (data != null && token != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
        state = state.copyWith(isLoggedIn: true, user: user);
      } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.post(ApiConstants.login, data: {'email': email, 'password': password});
      final d = resp.data['data'] as Map<String, dynamic>;
      await _api.saveToken(d['access_token'] as String);
      final user = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'Login failed. Check credentials.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error. Is the server running?');
      return false;
    }
  }

  Future<bool> signup(String email, String password, String fullName, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.post(ApiConstants.signup, data: {
        'email': email, 'password': password, 'full_name': fullName, 'role': role,
      });
      final d = resp.data['data'] as Map<String, dynamic>;
      await _api.saveToken(d['access_token'] as String);
      final user = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'Signup failed.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error.');
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _storage.delete(key: 'user_data');
    state = const AuthState();
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
    _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

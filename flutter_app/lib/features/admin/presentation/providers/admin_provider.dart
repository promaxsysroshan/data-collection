import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/models.dart';

// ── Dashboard ─────────────────────────────────────────────────────────────────
class AdminDashboardState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  const AdminDashboardState({this.isLoading = false, this.data, this.error});
  AdminDashboardState copyWith({bool? isLoading, Map<String, dynamic>? data, String? error}) =>
      AdminDashboardState(isLoading: isLoading ?? this.isLoading, data: data ?? this.data, error: error);
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  AdminDashboardNotifier() : super(const AdminDashboardState());
  final _api = ApiClient.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.dashboardAdmin);
      state = state.copyWith(isLoading: false, data: r.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading dashboard');
    }
  }
}
final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) => AdminDashboardNotifier());

// ── Tasks ─────────────────────────────────────────────────────────────────────
class TasksState {
  final bool isLoading;
  final List<TaskModel> tasks;
  final String? error;
  const TasksState({this.isLoading = false, this.tasks = const [], this.error});
  TasksState copyWith({bool? isLoading, List<TaskModel>? tasks, String? error}) =>
      TasksState(isLoading: isLoading ?? this.isLoading, tasks: tasks ?? this.tasks, error: error);
}

class TasksNotifier extends StateNotifier<TasksState> {
  TasksNotifier() : super(const TasksState());
  final _api = ApiClient.instance;

  Future<void> load({String? status, String? assignedTo}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (assignedTo != null) params['assigned_to'] = assignedTo;
      final r = await _api.get(ApiConstants.tasks, queryParams: params.isEmpty ? null : params);
      final list = (r.data['data'] as List).map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, tasks: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading tasks');
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.tasks, data: data);
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.tasks}/$id', data: data);
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _api.delete('${ApiConstants.tasks}/$id');
      await load();
      return true;
    } catch (_) { return false; }
  }
}
final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) => TasksNotifier());

// ── Submissions (Admin) ───────────────────────────────────────────────────────
class SubmissionsState {
  final bool isLoading;
  final List<SubmissionModel> submissions;
  final String? error;
  const SubmissionsState({this.isLoading = false, this.submissions = const [], this.error});
  SubmissionsState copyWith({bool? isLoading, List<SubmissionModel>? submissions, String? error}) =>
      SubmissionsState(isLoading: isLoading ?? this.isLoading, submissions: submissions ?? this.submissions, error: error);
}

class SubmissionsNotifier extends StateNotifier<SubmissionsState> {
  SubmissionsNotifier() : super(const SubmissionsState());
  final _api = ApiClient.instance;

  Future<void> load({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = status != null ? {'status': status} : null;
      final r = await _api.get(ApiConstants.submissions, queryParams: params);
      final list = (r.data['data'] as List)
          .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, submissions: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error');
    }
  }

  Future<bool> review(String id, String status, String? remarks) async {
    try {
      await _api.patch('${ApiConstants.submissions}/$id/review', data: {'status': status, 'admin_remarks': remarks});
      await load();
      return true;
    } catch (_) { return false; }
  }

  // FIX: Delete submission (admin only) — removes files from server too
  Future<bool> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.submissions}/$id');
      await load();
      return true;
    } catch (_) { return false; }
  }
}
final submissionsProvider = StateNotifierProvider<SubmissionsNotifier, SubmissionsState>((ref) => SubmissionsNotifier());

// ── Users List ────────────────────────────────────────────────────────────────
class UsersListState {
  final bool isLoading;
  final List<UserModel> users;
  final String? error;
  const UsersListState({this.isLoading = false, this.users = const [], this.error});
  UsersListState copyWith({bool? isLoading, List<UserModel>? users, String? error}) =>
      UsersListState(isLoading: isLoading ?? this.isLoading, users: users ?? this.users, error: error);
}

class UsersListNotifier extends StateNotifier<UsersListState> {
  UsersListNotifier() : super(const UsersListState());
  final _api = ApiClient.instance;

  Future<void> load({String role = 'level1'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.users, queryParams: {'role': role});
      final list = (r.data['data'] as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, users: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error');
    }
  }

  Future<bool> topupWallet(String userId, double amount, String desc) async {
    try {
      await _api.post(ApiConstants.walletTopup, data: {'user_id': userId, 'amount': amount, 'description': desc});
      await load();
      return true;
    } catch (_) { return false; }
  }
}
final usersListProvider = StateNotifierProvider<UsersListNotifier, UsersListState>((ref) => UsersListNotifier());

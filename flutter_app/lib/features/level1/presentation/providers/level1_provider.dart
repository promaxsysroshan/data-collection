import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/models.dart';

// ── Dashboard ─────────────────────────────────────────────────────────────────
class L1DashboardState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  const L1DashboardState({this.isLoading = false, this.data, this.error});
  L1DashboardState copyWith({bool? isLoading, Map<String, dynamic>? data, String? error}) =>
      L1DashboardState(isLoading: isLoading ?? this.isLoading, data: data ?? this.data, error: error);
}

class L1DashboardNotifier extends StateNotifier<L1DashboardState> {
  L1DashboardNotifier() : super(const L1DashboardState());
  final _api = ApiClient.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.dashboardL1);
      state = state.copyWith(isLoading: false, data: r.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading dashboard');
    }
  }
}
final l1DashboardProvider = StateNotifierProvider<L1DashboardNotifier, L1DashboardState>((ref) => L1DashboardNotifier());

// ── My Tasks ──────────────────────────────────────────────────────────────────
class MyTasksState {
  final bool isLoading;
  final List<TaskModel> tasks;
  final String? error;
  const MyTasksState({this.isLoading = false, this.tasks = const [], this.error});
  MyTasksState copyWith({bool? isLoading, List<TaskModel>? tasks, String? error}) =>
      MyTasksState(isLoading: isLoading ?? this.isLoading, tasks: tasks ?? this.tasks, error: error);
}

class MyTasksNotifier extends StateNotifier<MyTasksState> {
  MyTasksNotifier() : super(const MyTasksState());
  final _api = ApiClient.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.tasks);
      final list = (r.data['data'] as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, tasks: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading tasks');
    }
  }

  Future<bool> startTask(String taskId) async {
    try {
      await _api.patch('${ApiConstants.tasks}/$taskId/start');
      await load();
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'Failed to start task';
      state = state.copyWith(error: msg);
      return false;
    } catch (_) {
      return false;
    }
  }
}
final myTasksProvider = StateNotifierProvider<MyTasksNotifier, MyTasksState>((ref) => MyTasksNotifier());

// ── My Submissions ────────────────────────────────────────────────────────────
class MySubmissionsState {
  final bool isLoading;
  final List<SubmissionModel> submissions;
  final String? error;
  const MySubmissionsState({this.isLoading = false, this.submissions = const [], this.error});
  MySubmissionsState copyWith({bool? isLoading, List<SubmissionModel>? submissions, String? error}) =>
      MySubmissionsState(isLoading: isLoading ?? this.isLoading, submissions: submissions ?? this.submissions, error: error);
}

class MySubmissionsNotifier extends StateNotifier<MySubmissionsState> {  
  MySubmissionsNotifier() : super(const MySubmissionsState());
  final _api = ApiClient.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.submissions);
      final list = (r.data['data'] as List)
          .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, submissions: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading submissions');
    }
  }

  // Returns null on success, or an error message string on failure
  Future<String?> submitTask({
    required String taskId,
    required String? notes,
    required List<Map<String, dynamic>> files, // {path, name, mimeType}
  }) async {
    try {
         final multipartFiles = <dio_lib.MultipartFile>[];

     for (final f in files) {
       final mf = dio_lib.MultipartFile.fromBytes(
         f['bytes'],
         filename: f['name'] as String,
         contentType: dio_lib.DioMediaType.parse(
           f['mimeType'] as String? ?? 'application/octet-stream',
         ),
       );

       multipartFiles.add(mf);
      }   

      final formData = dio_lib.FormData();

     formData.fields.add(MapEntry('task_id', taskId));

     if (notes != null && notes.isNotEmpty) {
       formData.fields.add(MapEntry('notes', notes));
     }

     // 🔥 IMPORTANT FIX: add files one by one
     for (final file in multipartFiles) {
       formData.files.add(MapEntry('files', file));
     }

      await _api.postForm(ApiConstants.submissions, data: formData);
      await load();
      return null; // success
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      final msg = detail?.toString() ?? 'Submission failed. Please try again.';
      print('❌ submitTask DioException: $msg');
      return msg;
    } catch (e) {
      print('❌ submitTask error: $e');
      return 'Unexpected error. Please try again.';
    }
  }
}
final mySubmissionsProvider = StateNotifierProvider<MySubmissionsNotifier, MySubmissionsState>((ref) => MySubmissionsNotifier());

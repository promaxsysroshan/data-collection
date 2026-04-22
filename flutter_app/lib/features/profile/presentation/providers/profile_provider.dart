import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/models.dart';

class ProfileState {
  final bool isLoading;
  final bool isSaving;
  final UserModel? profile;
  final String? error;
  final String? successMsg;

  const ProfileState({this.isLoading = false, this.isSaving = false, this.profile, this.error, this.successMsg});
  ProfileState copyWith({bool? isLoading, bool? isSaving, UserModel? profile, String? error, String? successMsg}) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        profile: profile ?? this.profile,
        error: error,
        successMsg: successMsg,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());
  final _api = ApiClient.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiConstants.userProfile);
      final user = UserModel.fromJson(r.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, profile: user);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail']?.toString() ?? 'Error loading profile');
    }
  }

  Future<bool> update(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMsg: null);
    try {
      final r = await _api.patch(ApiConstants.userProfile, data: data);
      final user = UserModel.fromJson(r.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isSaving: false, profile: user, successMsg: 'Profile updated successfully!');
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: e.response?.data?['detail']?.toString() ?? 'Failed to update');
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier());

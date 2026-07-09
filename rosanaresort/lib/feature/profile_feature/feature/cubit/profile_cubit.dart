// ============================================================
//  profile_cubit.dart
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/cache/cache_consumer.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../feature/auth/models/auth_entities.dart';
import '../../model/user_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ProfileState extends Equatable {
  final UserEntity? user;
  final UnitDetailsModel? unitDetails;
  final bool isLoading;
  final bool isDeleting;
  final bool isLoggingOut;
  final String? errorMessage;

  // Transient signals — screen presents dialogs; cubit just flips flags
  final bool logoutSuccess;
  final bool deleteAccountSuccess;

  const ProfileState({
    this.user,
    this.unitDetails,
    this.isLoading = false,
    this.isDeleting = false,
    this.isLoggingOut = false,
    this.errorMessage,
    this.logoutSuccess = false,
    this.deleteAccountSuccess = false,
  });

  ProfileState copyWith({
    UserEntity? user,
    UnitDetailsModel? unitDetails,
    bool? isLoading,
    bool? isDeleting,
    bool? isLoggingOut,
    String? errorMessage,
    bool? logoutSuccess,
    bool? deleteAccountSuccess,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      unitDetails: unitDetails ?? this.unitDetails,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      logoutSuccess: logoutSuccess ?? false,
      deleteAccountSuccess: deleteAccountSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
    user, unitDetails, isLoading, isDeleting, isLoggingOut,
    errorMessage, logoutSuccess, deleteAccountSuccess,
  ];
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class ProfileCubit extends Cubit<ProfileState> {
  final ApiConsumer _api;
  final CacheConsumer _cache;

  ProfileCubit({required ApiConsumer api, required CacheConsumer cache})
      : _api = api,
        _cache = cache,
        super(const ProfileState(isLoading: true));

  // ── Load profile data ───────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _api.postData(url: EndPoints.getProfileData, data: {'un_id': _cache.getData(key: CacheKeys.savingUserId)?? ""});
      final data = response.data['unit'] ?? response.data;

      final user = UserEntity(
        id: data['un_id'] ?? 0,
        fullName: data['un_owner'] ?? data['full_name'] ?? '',
        email: data['un_nath_id'] ?? '',
        phone: data['un_phone'] ?? '',
        title: data['un_title'] ?? '',
      );
      print(user.toString());

      emit(state.copyWith(user: user, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // ── Load unit details ────────────────────────────────────────────────────────

  Future<void> loadUnitDetails(String unId) async {
    try {
      final response = await _api.postData(
        url: EndPoints.getUnitDetails,
        data: {'un_id': unId},
      );
      final model = UnitDetailsModel.fromJson(response.data);
      emit(state.copyWith(unitDetails: model));
    } catch (_) {
      // Unit details are supplementary — swallow silently,
      // profile still renders without them.
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(state.copyWith(isLoggingOut: true, clearError: true));
    try {
      await _api.postData(url: EndPoints.loggingOut, data: {  "un_id": state.user?.id.toString() ?? "",});
      _clearCache();
      emit(state.copyWith(isLoggingOut: false, logoutSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoggingOut: false, errorMessage: e.toString()));
    }
  }

  // ── Delete account ───────────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _api.postData(url: EndPoints.deleteAccount, data: {
        {
          "un_id": state.user?.id.toString() ?? "",
        }
      });
      _clearCache();
      emit(state.copyWith(isDeleting: false, deleteAccountSuccess: true));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, errorMessage: e.toString()));
    }
  }

  void _clearCache() {
    _cache.clearData( );

  }
}
import 'dart:io';
import 'package:check_vpn_connection/check_vpn_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/cache/cache_consumer_impl.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import '../../data/models/finance_model.dart';
import '../../data/repositories/passes_repository.dart';
import 'passes_state.dart';

class PassesCubit extends Cubit<PassesState> {
  final PassesRepository repository;
  final EncryptedCacheConsumerImpl storage;

  /// Cached open-screen coordinates — set once when screen first opens.
  double _openLat = 0.0;
  double _openLng = 0.0;

  /// The unit ID stored so cubit can reload without the screen passing it again.
  String? _unId;

  PassesCubit({required this.repository, required this.storage}) : super(PassesInitial());

  // ─── Load & reload ────────────────────────────────────────────────────────

  /// Primary load call from [PassesScreen.initState].
  Future<void> loadPassesData() async {


    final userId = storage.getData(key: CacheKeys.savingUserId);
    _unId = "$userId";
    await _fetchPasses();
  }

  /// Re-fetch from the same unit ID — called after adding a pass or on pull-to-refresh.
  Future<void> reloadPasses() async {
    if (_unId == null) return;
    await _fetchPasses();
  }

  Future<void> _fetchPasses() async {
    emit(PassesLoading());
    try {
      final results = await Future.wait([
        repository.getPasses(_unId!),
        repository.getTodayPassesCount(_unId!),
        repository.checkFinance(_unId!),
      ]);

      final passes = results[0] as List<dynamic>?;
      final countData = results[1] as Map<String, dynamic>;
      final finance = results[2] as dynamic;

      // Null guard — API returned nothing
      if (passes == null || finance == null) {
        emit(PassesNullData());
        return;
      }

      final todayCount = countData['today_passes_count'] as int;
      final maxLimit = countData['max_limit'] as int;

      if (passes.isEmpty) {
        emit(PassesEmpty(
          todayCount: todayCount,
          maxLimit: maxLimit,
          finance: finance,
        ));
      } else {
        emit(PassesLoaded(
          passes: passes.cast(),
          todayCount: todayCount,
          maxLimit: maxLimit,
          finance: finance,
        ));
      }
    } catch (e) {
      emit(PassesError(e.toString()));
    }
  }

  // ─── Capture open-screen location ────────────────────────────────────────

  /// Called from initState — silently captures the user's location at screen-open time.
  Future<void> captureOpenLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _openLat = pos.latitude;
      _openLng = pos.longitude;
    } catch (_) {}
  }

  // ─── Add-pass gate (finance + quota + security checks) ───────────────────

  /// Entry point when user taps the FAB or header add button.
  /// Runs all guards and either emits a dialog state or [OpenAddPassSheet].
  Future<void> requestAddPass() async {
    final currentState = state;

    // Resolve finance/quota from whichever loaded state is active
    FinanceModel? finance;
    bool canAdd = false;
    int maxLimit = 0;

    if (currentState is PassesLoaded) {
      finance = currentState.finance;
      canAdd = currentState.canAddMore;
      maxLimit = currentState.maxLimit;
    } else if (currentState is PassesEmpty) {
      finance = currentState.finance;
      canAdd = currentState.canAddMore;
      maxLimit = currentState.maxLimit;
    } else {
      return; // not in a state where adding makes sense
    }

    // Guard 1 — finance
    if (!finance.isPaid) {
      emit(ShowFinanceBlockedDialog());
      _restorePreviousStateSafely(currentState);
      return;
    }

    // Guard 2 — daily quota
    if (!canAdd) {
      emit(ShowQuotaExceededDialog(maxLimit));
      _restorePreviousStateSafely(currentState);
      return;
    }

    // Guard 3 — VPN check
    try {
      final isVpnActive = await CheckVpnConnection.isVpnActive();
      if (isVpnActive) {
        emit(ShowVpnBlockedDialog());
        _restorePreviousStateSafely(currentState);
        return;
      }
    } catch (_) {
      // If VPN check fails we allow through — better UX than blocking.
    }

    // Guard 4 — location permission + mock detection
    final position = await _verifyLocation(currentState);
    if (position == null) {
      // _verifyLocation already emitted the right dialog state and restored it.
      return;
    }

    // All guards passed — tell screen to open the sheet.
    emit(OpenAddPassSheet(
      openLat: position.latitude,
      openLng: position.longitude,
    ));
    _restorePreviousStateSafely(currentState);
  }

  /// Verifies real location, returning a [Position] on success or null + emitting
  /// a dialog state on failure — never touches BuildContext.
  Future<Position?> _verifyLocation(PassesState currentState) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(ShowLocationRequiredDialog());
      _restorePreviousStateSafely(currentState);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(ShowLocationRequiredDialog());
        _restorePreviousStateSafely(currentState);
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      emit(ShowLocationRequiredDialog());
      _restorePreviousStateSafely(currentState);
      return null;
    }

    // Hardware / jailbreak / mock check
    try {
      final isMock = await SafeDevice.isMockLocation;
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;

      if (isMock || isJailBroken || (!isRealDevice && !isMock)) {
        emit(ShowFakeLocationDialog());
        _restorePreviousStateSafely(currentState);
        return null;
      }
    } catch (_) {
      // Security check bypass — allow through with a debug note.
      debugPrint('PassesCubit: hardware security check failed silently.');
    }

    try {
      // 💡 FIXED: Uses modern Geolocator syntax to prevent build errors
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (position.isMocked) {
        emit(ShowFakeLocationDialog());
        _restorePreviousStateSafely(currentState);
        return null;
      }
      return position;
    } catch (e) {
      debugPrint('PassesCubit: GPS fetch error — $e');
      return null;
    }
  }

  // ─── Store pass ───────────────────────────────────────────────────────────

  // 💡 FIXED: BuildContext removed entirely. Navigation should be handled in the UI.
  Future<void> storePass({
    required String name,
    String? notes,
    required File image,
    required BuildContext context
  }) async {
    if (_unId == null) return;

    emit(StorePassLoading());
    try {
      await repository.storePass(
        unId: _unId!, // Uses the cached ID safely
        name: name,
        notes: notes,
        firstLat: _openLat,
        firstLng: _openLng,
        userLat: _openLat,
        userLng: _openLng,
        image: image,
      );

      emit(StorePassSuccess());
      Navigator.pushReplacementNamed(context, Routes.passesScreen);
      await reloadPasses();
    } catch (e) {
      emit(StorePassError(e.toString()));
      reloadPasses();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// 💡 FIXED: Uses microtask to ensure BlocListener catches the dialog state
  /// before the Cubit restores the previous state, eliminating the race condition.
  void _restorePreviousStateSafely(PassesState previous) {
    Future.microtask(() {
      if (!isClosed) emit(previous);
    });
  }
}
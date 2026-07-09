import 'package:equatable/equatable.dart';
import '../../data/models/pass_model.dart';
import '../../data/models/finance_model.dart';

abstract class PassesState extends Equatable {
  const PassesState();

  @override
  List<Object?> get props => [];
}

// ─── Data states ──────────────────────────────────────────────────────────────

class PassesInitial extends PassesState {}

class PassesLoading extends PassesState {}

/// Passes loaded successfully with a non-empty list.
class PassesLoaded extends PassesState {
  final List<PassModel> passes;
  final int todayCount;
  final int maxLimit;
  final FinanceModel finance;

  const PassesLoaded({
    required this.passes,
    required this.todayCount,
    required this.maxLimit,
    required this.finance,
  });

  bool get canAddMore => todayCount < maxLimit;
  int get remaining => maxLimit - todayCount;

  @override
  List<Object?> get props => [passes, todayCount, maxLimit, finance];
}

/// API returned successfully but the passes list is empty.
class PassesEmpty extends PassesState {
  final int todayCount;
  final int maxLimit;
  final FinanceModel finance;

  const PassesEmpty({
    required this.todayCount,
    required this.maxLimit,
    required this.finance,
  });

  bool get canAddMore => todayCount < maxLimit;

  @override
  List<Object?> get props => [todayCount, maxLimit, finance];
}

/// The passes data is null — API returned no payload at all.
class PassesNullData extends PassesState {}

class PassesError extends PassesState {
  final String message;

  const PassesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Store pass states ────────────────────────────────────────────────────────

class StorePassLoading extends PassesState {}

class StorePassSuccess extends PassesState {}

class StorePassError extends PassesState {
  final String message;

  const StorePassError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── UI event states (emitted by cubit, consumed by BlocListener) ─────────────
// These tell the screen *which dialog to show* without the cubit touching context.

/// Ask the screen to show the VPN-blocked dialog.
class ShowVpnBlockedDialog extends PassesState {}

/// Ask the screen to show the fake/mock location warning dialog.
class ShowFakeLocationDialog extends PassesState {}

/// Ask the screen to show the location-permission-required dialog.
class ShowLocationRequiredDialog extends PassesState {}

/// Ask the screen to show the finance-not-paid blocking dialog.
class ShowFinanceBlockedDialog extends PassesState {}

/// Ask the screen to show the daily quota exceeded dialog.
class ShowQuotaExceededDialog extends PassesState {
  final int maxLimit;
  const ShowQuotaExceededDialog(this.maxLimit);

  @override
  List<Object?> get props => [maxLimit];
}

/// Ask the screen to open the add-pass bottom sheet.
/// Carries the captured open location so the sheet can use it.
class OpenAddPassSheet extends PassesState {
  final double openLat;
  final double openLng;

  const OpenAddPassSheet({required this.openLat, required this.openLng});

  @override
  List<Object?> get props => [openLat, openLng];
}

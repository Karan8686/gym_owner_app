import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';

// ---------------------------------------------------------------------------
// Dashboard controller — async state for the dashboard screen.
// ---------------------------------------------------------------------------

/// Combined dashboard data loaded as a single async unit.
class DashboardData {
  const DashboardData({
    required this.stats,
    required this.renewalsDue,
  });

  final DashboardStats stats;
  final List<RenewalDueItem> renewalsDue;
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<DashboardData> {
  late final DashboardRepository _repo;

  @override
  FutureOr<DashboardData> build() async {
    _repo = ref.read(dashboardRepositoryProvider);
    return _fetchAll();
  }

  Future<DashboardData> _fetchAll() async {
    final results = await Future.wait([
      _repo.getStats(),
      _repo.getRenewalsDue(),
    ]);

    return DashboardData(
      stats: results[0] as DashboardStats,
      renewalsDue: results[1] as List<RenewalDueItem>,
    );
  }

  /// Pull-to-refresh — re-fetches everything.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll());
  }
}

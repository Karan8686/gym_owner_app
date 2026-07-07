import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';

final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsStats>(
  AnalyticsController.new,
);

class AnalyticsController extends AsyncNotifier<AnalyticsStats> {
  late final AnalyticsRepository _repo;

  @override
  FutureOr<AnalyticsStats> build() async {
    _repo = ref.read(analyticsRepositoryProvider);
    return _repo.getAnalytics();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAnalytics());
  }
}

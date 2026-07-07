import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pricing_repository.dart';
import '../domain/plan_price.dart';

final planPricingControllerProvider = AsyncNotifierProvider<
    PlanPricingController, List<PlanPrice>>(
  PlanPricingController.new,
);

class PlanPricingController extends AsyncNotifier<List<PlanPrice>> {
  late final PricingRepository _repo;

  @override
  FutureOr<List<PlanPrice>> build() async {
    _repo = ref.read(pricingRepositoryProvider);
    return _repo.getPrices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getPrices());
  }

  Future<void> savePrices(List<PlanPrice> updatedPrices) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updatePrices(updatedPrices);
      // Invalidate pricing repository dependencies (like add member screen & renew screen lookups)
      ref.invalidate(pricingRepositoryProvider);
      return updatedPrices;
    });
  }
}

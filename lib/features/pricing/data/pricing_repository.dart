import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/core/config/supabase_config.dart';
import '../domain/plan_price.dart';

final pricingRepositoryProvider = Provider<PricingRepository>((ref) {
  return PricingRepository();
});

class PricingRepository {
  PricingRepository();

  /// Default fallback prices as per Stitch design files (1, 3, 6, 12 months)
  static const List<PlanPrice> defaultPrices = [
    // Weight-only (Basic)
    PlanPrice(id: 'w1', planType: 'weight', durationMonths: 1, price: 45.0),
    PlanPrice(id: 'w3', planType: 'weight', durationMonths: 3, price: 120.0),
    PlanPrice(id: 'w6', planType: 'weight', durationMonths: 6, price: 220.0),
    PlanPrice(id: 'w12', planType: 'weight', durationMonths: 12, price: 400.0),
    // Cardio + Weight (Premium)
    PlanPrice(id: 'cw1', planType: 'cardio_weight', durationMonths: 1, price: 60.0),
    PlanPrice(id: 'cw3', planType: 'cardio_weight', durationMonths: 3, price: 160.0),
    PlanPrice(id: 'cw6', planType: 'cardio_weight', durationMonths: 6, price: 300.0),
    PlanPrice(id: 'cw12', planType: 'cardio_weight', durationMonths: 12, price: 550.0),
  ];

  /// Fetch all pricing options from Supabase. Fallback to default prices if table is empty or query fails.
  Future<List<PlanPrice>> getPrices() async {
    try {
      final response = await supabase.from('plan_prices').select();
      final list = response as List<dynamic>;
      if (list.isEmpty) {
        return defaultPrices;
      }
      return list.map((r) => PlanPrice.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback on network or DB table missing errors
      return defaultPrices;
    }
  }

  /// Get a single price by plan type and duration.
  Future<double> getPriceFor({
    required String planType,
    required int durationMonths,
  }) async {
    final prices = await getPrices();
    final match = prices.firstWhere(
      (p) => p.planType == planType && p.durationMonths == durationMonths,
      orElse: () => PlanPrice(
        id: 'temp',
        planType: planType,
        durationMonths: durationMonths,
        price: planType == 'weight' ? (45.0 * durationMonths) : (60.0 * durationMonths),
      ),
    );
    return match.price;
  }

  /// Update all pricing records in Supabase.
  Future<void> updatePrices(List<PlanPrice> prices) async {
    final list = prices.map((p) => p.toJson()).toList();
    await supabase.from('plan_prices').upsert(list);
  }
}

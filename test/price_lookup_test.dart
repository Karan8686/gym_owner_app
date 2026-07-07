import 'package:flutter_test/flutter_test.dart';
import 'package:gym_owner_app/features/pricing/data/pricing_repository.dart';

void main() {
  group('PricingRepository Price Lookup', () {
    late PricingRepository repository;

    setUp(() {
      repository = PricingRepository();
    });

    test('retrieves default price for weight plan (1 month)', () async {
      final price = await repository.getPriceFor(
        planType: 'weight',
        durationMonths: 1,
      );
      expect(price, 45.0);
    });

    test('retrieves default price for cardio_weight plan (3 months)', () async {
      final price = await repository.getPriceFor(
        planType: 'cardio_weight',
        durationMonths: 3,
      );
      expect(price, 160.0);
    });

    test('calculates a fallback price for non-standard duration', () async {
      final price = await repository.getPriceFor(
        planType: 'weight',
        durationMonths: 5,
      );
      // Fallback is 45.0 * duration = 225.0
      expect(price, 225.0);
    });
  });
}

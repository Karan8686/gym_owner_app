import 'package:flutter_test/flutter_test.dart';
import 'package:gym_owner_app/features/members/domain/membership_math.dart';

void main() {
  group('MembershipMath.calculateNewDueDate', () {
    test('extends from current due date if current due date is in the future', () {
      final now = DateTime(2026, 7, 7);
      final currentDueDate = DateTime(2026, 7, 10); // in future
      final durationMonths = 1;

      final newDueDate = MembershipMath.calculateNewDueDate(
        currentDueDate: currentDueDate,
        durationMonths: durationMonths,
        baseRenewalDate: now,
      );

      // Should extend from 2026-07-10 to 2026-08-10
      expect(newDueDate.year, 2026);
      expect(newDueDate.month, 8);
      expect(newDueDate.day, 10);
    });

    test('extends from base renewal date (now) if current due date is in the past (expired)', () {
      final now = DateTime(2026, 7, 7);
      final currentDueDate = DateTime(2026, 7, 1); // in past (expired)
      final durationMonths = 3;

      final newDueDate = MembershipMath.calculateNewDueDate(
        currentDueDate: currentDueDate,
        durationMonths: durationMonths,
        baseRenewalDate: now,
      );

      // Should extend from now (2026-07-07) to 3 months later (2026-10-07)
      expect(newDueDate.year, 2026);
      expect(newDueDate.month, 10);
      expect(newDueDate.day, 7);
    });

    test('correctly handles end-of-month day overflows (e.g. Jan 31 + 1 month -> Feb 28)', () {
      final baseDate = DateTime(2026, 1, 31);
      final newDate = MembershipMath.addMonths(baseDate, 1);

      expect(newDate.year, 2026);
      expect(newDate.month, 2);
      expect(newDate.day, 28); // Feb only has 28 days in 2026
    });

    test('correctly handles leap year end-of-month overflows (e.g. Jan 31 + 1 month in leap year -> Feb 29)', () {
      final baseDate = DateTime(2024, 1, 31); // 2024 is leap year
      final newDate = MembershipMath.addMonths(baseDate, 1);

      expect(newDate.year, 2024);
      expect(newDate.month, 2);
      expect(newDate.day, 29); // Feb has 29 days in 2024
    });
  });
}

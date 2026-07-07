import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/supabase_config.dart';
import '../../members/domain/membership.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

class AnalyticsStats {
  const AnalyticsStats({
    required this.currentMonthRevenue,
    required this.revenueChangePercentage,
    required this.monthlyHistory,
    required this.weightPlanCount,
    required this.weightPlanRevenue,
    required this.cardioPlanCount,
    required this.cardioPlanRevenue,
  });

  final double currentMonthRevenue;
  final double revenueChangePercentage;
  final List<MonthlyRevenue> monthlyHistory;
  final int weightPlanCount;
  final double weightPlanRevenue;
  final int cardioPlanCount;
  final double cardioPlanRevenue;
}

class MonthlyRevenue {
  const MonthlyRevenue({
    required this.monthLabel,
    required this.revenue,
  });

  final String monthLabel;
  final double revenue;
}

class AnalyticsRepository {
  AnalyticsRepository();

  Future<AnalyticsStats> getAnalytics() async {
    final now = DateTime.now();

    // 1. Fetch memberships with payments
    final membershipsResponse = await supabase
        .from('memberships')
        .select()
        .not('payment_date', 'is', null);

    final memberships = (membershipsResponse as List<dynamic>)
        .map((m) => Membership.fromJson(m as Map<String, dynamic>))
        .toList();

    // 2. Compute current month's revenue and last month's revenue
    double currentMonthRevenue = 0.0;
    double lastMonthRevenue = 0.0;

    final currentMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = currentMonthStart.subtract(const Duration(seconds: 1));

    for (final m in memberships) {
      if (m.paymentDate == null) continue;
      final pDate = m.paymentDate!;

      if (pDate.isAfter(currentMonthStart) || pDate.isAtSameMomentAs(currentMonthStart)) {
        currentMonthRevenue += m.priceCharged;
      } else if ((pDate.isAfter(lastMonthStart) || pDate.isAtSameMomentAs(lastMonthStart)) &&
          pDate.isBefore(lastMonthEnd)) {
        lastMonthRevenue += m.priceCharged;
      }
    }

    // Percentage change vs last month
    double changePct = 0.0;
    if (lastMonthRevenue > 0) {
      changePct = ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
    } else if (currentMonthRevenue > 0) {
      changePct = 100.0; // 100% increase if last month had no revenue
    }

    // 3. Compute 6 months history (up to current month)
    final historyList = <MonthlyRevenue>[];
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final label = DateFormat('MMM').format(targetMonth);

      double monthRevenue = 0.0;
      for (final m in memberships) {
        if (m.paymentDate == null) continue;
        final pDate = m.paymentDate!;
        if ((pDate.isAfter(targetMonth) || pDate.isAtSameMomentAs(targetMonth)) &&
            pDate.isBefore(nextMonth)) {
          monthRevenue += m.priceCharged;
        }
      }
      historyList.add(MonthlyRevenue(monthLabel: label, revenue: monthRevenue));
    }

    // 4. Compute Plan Breakdown
    int weightCount = 0;
    double weightRevenue = 0.0;
    int cardioCount = 0;
    double cardioRevenue = 0.0;

    for (final m in memberships) {
      if (m.planType == 'weight') {
        weightRevenue += m.priceCharged;
        if (m.status == MembershipStatus.active) {
          weightCount++;
        }
      } else if (m.planType == 'cardio_weight') {
        cardioRevenue += m.priceCharged;
        if (m.status == MembershipStatus.active) {
          cardioCount++;
        }
      }
    }

    return AnalyticsStats(
      currentMonthRevenue: currentMonthRevenue,
      revenueChangePercentage: changePct,
      monthlyHistory: historyList,
      weightPlanCount: weightCount,
      weightPlanRevenue: weightRevenue,
      cardioPlanCount: cardioCount,
      cardioPlanRevenue: cardioRevenue,
    );
  }
}

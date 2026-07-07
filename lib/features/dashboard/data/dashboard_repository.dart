import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/core/config/supabase_config.dart';

// ---------------------------------------------------------------------------
// Dashboard stats — counts for active / expiring / expired memberships.
// ---------------------------------------------------------------------------
class DashboardStats {
  const DashboardStats({
    required this.activeCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });

  final int activeCount;
  final int expiringSoonCount;
  final int expiredCount;
}

// ---------------------------------------------------------------------------
// A member row in the "Renewals Due" list.
// ---------------------------------------------------------------------------
class RenewalDueItem {
  const RenewalDueItem({
    required this.memberId,
    required this.memberName,
    required this.planLabel,
    required this.daysRemaining,
  });

  final String memberId;
  final String memberName;
  final String planLabel;
  final int daysRemaining;
}

// ---------------------------------------------------------------------------
// Dashboard Repository — queries the Supabase DB for dashboard data.
// ---------------------------------------------------------------------------

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardRepository {
  DashboardRepository();

  /// Fetch membership counts by status.
  ///
  /// "Expiring soon" = active memberships with `due_date` within the next
  /// 7 days. The status column itself is the source of truth (set by the
  /// server-side pg_cron job), so we never compute it client-side.
  Future<DashboardStats> getStats() async {
    // Active count
    final activeResult = await supabase
        .from('memberships')
        .select()
        .eq('status', 'active')
        .count();

    // Expiring soon = active + due_date within the next 7 days
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final expiringSoonResult = await supabase
        .from('memberships')
        .select()
        .eq('status', 'active')
        .lte('due_date', sevenDaysFromNow.toIso8601String())
        .gte('due_date', now.toIso8601String())
        .count();

    // Expired count
    final expiredResult = await supabase
        .from('memberships')
        .select()
        .eq('status', 'expired')
        .count();

    return DashboardStats(
      activeCount: activeResult.count,
      expiringSoonCount: expiringSoonResult.count,
      expiredCount: expiredResult.count,
    );
  }

  /// Fetch members whose memberships are due within the next 7 days,
  /// sorted by soonest first. Includes recently expired (up to 3 days past).
  Future<List<RenewalDueItem>> getRenewalsDue() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    final result = await supabase
        .from('memberships')
        .select('id, due_date, plan_type, duration_months, member_id, members!inner(id, name)')
        .inFilter('status', ['active', 'expired'])
        .gte('due_date', threeDaysAgo.toIso8601String())
        .lte('due_date', sevenDaysFromNow.toIso8601String())
        .order('due_date', ascending: true);

    final rows = result as List<dynamic>;
    return rows.map((row) {
      final member = row['members'] as Map<String, dynamic>;
      final dueDate = DateTime.parse(row['due_date'] as String);
      final daysRemaining = dueDate.difference(now).inDays;

      final durationMonths = row['duration_months'] as int;
      final planType = row['plan_type'] as String;

      final duration = switch (durationMonths) {
        1  => 'Monthly',
        3  => 'Quarterly',
        6  => 'Half-Year',
        12 => 'Annual',
        _  => '$durationMonths-Month',
      };
      final type = switch (planType) {
        'weight'        => 'Basic',
        'cardio_weight' => 'Premium',
        _               => planType,
      };

      return RenewalDueItem(
        memberId: member['id'] as String,
        memberName: member['name'] as String,
        planLabel: '$duration $type',
        daysRemaining: daysRemaining,
      );
    }).toList();
  }
}

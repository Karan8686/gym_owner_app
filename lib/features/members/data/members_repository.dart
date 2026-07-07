import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/core/config/supabase_config.dart';

import '../domain/member.dart';
import '../domain/membership.dart';
import '../domain/membership_math.dart';

// ---------------------------------------------------------------------------
// Members Repository — all member + membership Supabase queries.
// ---------------------------------------------------------------------------

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository();
});

/// Combines a member with their latest membership for list display.
class MemberWithMembership {
  const MemberWithMembership({
    required this.member,
    this.latestMembership,
  });

  final Member member;
  final Membership? latestMembership;

  /// Days remaining on the active/latest membership.
  /// Null if no membership exists.
  int? get daysRemaining => latestMembership?.daysRemaining;

  /// Current status string from the latest membership.
  String? get statusLabel => latestMembership?.status.name;
}

/// Status filter for the member list.
enum MemberStatusFilter { all, active, expiring, expired }

class MembersRepository {
  MembersRepository();

  /// Fetch all members with their latest membership, optionally filtered.
  ///
  /// The join pulls each member's most recent membership row.
  Future<List<MemberWithMembership>> getMembers({
    MemberStatusFilter filter = MemberStatusFilter.all,
    String? searchQuery,
  }) async {
    // Fetch members
    var query = supabase.from('members').select();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('name.ilike.%$q%,phone_no.ilike.%$q%');
    }

    final membersResult = await query.order('name', ascending: true);
    final memberRows = membersResult as List<dynamic>;

    if (memberRows.isEmpty) return [];

    // Fetch latest membership per member in a single query
    final memberIds = memberRows.map((r) => r['id'] as String).toList();
    final membershipsResult = await supabase
        .from('memberships')
        .select()
        .inFilter('member_id', memberIds)
        .order('due_date', ascending: false);

    final membershipRows = membershipsResult as List<dynamic>;

    // Group: latest membership per member_id
    final latestByMember = <String, Map<String, dynamic>>{};
    for (final row in membershipRows) {
      final memberId = row['member_id'] as String;
      latestByMember.putIfAbsent(memberId, () => row);
    }

    // Build combined list
    final results = <MemberWithMembership>[];
    for (final mRow in memberRows) {
      final member = Member.fromJson(mRow as Map<String, dynamic>);
      final mshipRow = latestByMember[member.id];
      Membership? membership;
      if (mshipRow != null) {
        membership = Membership.fromJson(mshipRow);
      }

      // Apply status filter
      if (filter != MemberStatusFilter.all) {
        if (membership == null) continue;
        final now = DateTime.now();
        switch (filter) {
          case MemberStatusFilter.active:
            if (membership.status != MembershipStatus.active) continue;
            break;
          case MemberStatusFilter.expiring:
            if (membership.status != MembershipStatus.active) continue;
            final daysLeft = membership.dueDate.difference(now).inDays;
            if (daysLeft > 7) continue; // expiring = within 7 days
            break;
          case MemberStatusFilter.expired:
            if (membership.status != MembershipStatus.expired) continue;
            break;
          case MemberStatusFilter.all:
            break;
        }
      }

      results.add(MemberWithMembership(
        member: member,
        latestMembership: membership,
      ));
    }

    return results;
  }

  /// Fetch a single member by ID.
  Future<Member> getMemberById(String id) async {
    final result = await supabase
        .from('members')
        .select()
        .eq('id', id)
        .single();
    return Member.fromJson(result);
  }

  /// Fetch all memberships for a member, newest first.
  Future<List<Membership>> getMembershipsByMemberId(String memberId) async {
    final result = await supabase
        .from('memberships')
        .select()
        .eq('member_id', memberId)
        .order('due_date', ascending: false);
    return (result as List<dynamic>)
        .map((r) => Membership.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Get the next sequential serial number for a new member.
  Future<int> _getNextSrNo() async {
    try {
      final response = await supabase
          .from('members')
          .select('sr_no')
          .order('sr_no', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return 1;
      return (response['sr_no'] as int) + 1;
    } catch (_) {
      return 1;
    }
  }

  /// Create a new member, their initial membership, and a confirmed payment record.
  Future<void> createMember({
    required String name,
    required String phoneNo,
    required String planType,
    required int durationMonths,
    required double priceCharged,
    required DateTime startDate,
  }) async {
    final srNo = await _getNextSrNo();

    // 1. Insert Member
    final memberResponse = await supabase.from('members').insert({
      'sr_no': srNo,
      'name': name,
      'phone_no': phoneNo,
    }).select().single();

    final memberId = memberResponse['id'] as String;

    // Calculate due date
    final dueDate = MembershipMath.calculateNewDueDate(
      currentDueDate: startDate,
      durationMonths: durationMonths,
      baseRenewalDate: startDate,
    );

    // 2. Insert Membership
    final membershipResponse = await supabase.from('memberships').insert({
      'member_id': memberId,
      'plan_type': planType,
      'duration_months': durationMonths,
      'price_charged': priceCharged,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': 'active',
    }).select().single();

    final membershipId = membershipResponse['id'] as String;

    // 3. Insert Confirmed Payment
    await supabase.from('payments').insert({
      'member_id': memberId,
      'membership_id': membershipId,
      'amount': priceCharged,
      'status': 'confirmed',
      'paid_at': DateTime.now().toIso8601String(),
      'confirmed_at': DateTime.now().toIso8601String(),
      'confirmed_by': supabase.auth.currentUser?.id,
    });
  }

  /// Update member details.
  Future<void> updateMember({
    required String id,
    required String name,
    required String phoneNo,
  }) async {
    await supabase.from('members').update({
      'name': name,
      'phone_no': phoneNo,
    }).eq('id', id);
  }

  /// Remove a member and all their associated records.
  Future<void> deleteMember(String id) async {
    await supabase.from('payments').delete().eq('member_id', id);
    await supabase.from('memberships').delete().eq('member_id', id);
    await supabase.from('members').delete().eq('id', id);
  }

  /// Renew an existing member's membership.
  Future<void> renewMembership({
    required String memberId,
    required String planType,
    required int durationMonths,
    required double priceCharged,
  }) async {
    final memberships = await getMembershipsByMemberId(memberId);
    final now = DateTime.now();

    final DateTime baseDueDate = memberships.isNotEmpty
        ? memberships.first.dueDate
        : now;

    final newDueDate = MembershipMath.calculateNewDueDate(
      currentDueDate: baseDueDate,
      durationMonths: durationMonths,
      baseRenewalDate: now,
    );

    final startDate = baseDueDate.isAfter(now) ? baseDueDate : now;

    // Insert new membership
    final membershipResponse = await supabase.from('memberships').insert({
      'member_id': memberId,
      'plan_type': planType,
      'duration_months': durationMonths,
      'price_charged': priceCharged,
      'start_date': startDate.toIso8601String(),
      'due_date': newDueDate.toIso8601String(),
      'status': 'active',
    }).select().single();

    final membershipId = membershipResponse['id'] as String;

    // Insert confirmed payment
    await supabase.from('payments').insert({
      'member_id': memberId,
      'membership_id': membershipId,
      'amount': priceCharged,
      'status': 'confirmed',
      'paid_at': now.toIso8601String(),
      'confirmed_at': now.toIso8601String(),
      'confirmed_by': supabase.auth.currentUser?.id,
    });
  }
}

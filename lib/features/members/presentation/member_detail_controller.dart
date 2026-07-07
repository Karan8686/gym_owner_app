import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/core/config/supabase_config.dart';

import '../data/members_repository.dart';
import '../domain/member.dart';
import '../domain/membership.dart';

// ---------------------------------------------------------------------------
// Payment model (minimal — just for the detail screen's payment history).
// Full payments feature will expand this later.
// ---------------------------------------------------------------------------
class PaymentSummary {
  const PaymentSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.paidAt,
  });

  final String id;
  final double amount;
  final String status; // 'pending' | 'confirmed' | 'rejected'
  final DateTime paidAt;
}

// ---------------------------------------------------------------------------
// Combined detail data
// ---------------------------------------------------------------------------
class MemberDetailData {
  const MemberDetailData({
    required this.member,
    required this.memberships,
    required this.payments,
  });

  final Member member;
  final List<Membership> memberships;
  final List<PaymentSummary> payments;

  Membership? get latestMembership =>
      memberships.isNotEmpty ? memberships.first : null;
}

// ---------------------------------------------------------------------------
// Detail controller — family provider keyed by memberId
// ---------------------------------------------------------------------------
final memberDetailControllerProvider = AsyncNotifierProvider.family<
    MemberDetailController, MemberDetailData, String>(
  MemberDetailController.new,
);

class MemberDetailController
    extends FamilyAsyncNotifier<MemberDetailData, String> {
  late final MembersRepository _repo;

  @override
  FutureOr<MemberDetailData> build(String memberId) async {
    _repo = ref.read(membersRepositoryProvider);
    return _fetchAll(memberId);
  }

  Future<MemberDetailData> _fetchAll(String memberId) async {
    final results = await Future.wait([
      _repo.getMemberById(memberId),
      _repo.getMembershipsByMemberId(memberId),
      _fetchPayments(memberId),
    ]);

    return MemberDetailData(
      member: results[0] as Member,
      memberships: results[1] as List<Membership>,
      payments: results[2] as List<PaymentSummary>,
    );
  }

  Future<List<PaymentSummary>> _fetchPayments(String memberId) async {
    final result = await supabase
        .from('payments')
        .select('id, amount, status, paid_at')
        .eq('member_id', memberId)
        .order('paid_at', ascending: false);

    return (result as List<dynamic>).map((r) {
      return PaymentSummary(
        id: r['id'] as String,
        amount: (r['amount'] as num).toDouble(),
        status: r['status'] as String,
        paidAt: DateTime.parse(r['paid_at'] as String),
      );
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll(arg));
  }
}

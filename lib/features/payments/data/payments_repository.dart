import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/core/config/supabase_config.dart';

import '../domain/payment.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});

/// Combined payment detail for pending payments listing.
class PendingPaymentItem {
  const PendingPaymentItem({
    required this.payment,
    required this.memberName,
    required this.planLabel,
  });

  final Payment payment;
  final String memberName;
  final String planLabel;
}

class PaymentsRepository {
  PaymentsRepository();

  /// Fetch all pending payments with member and plan details.
  Future<List<PendingPaymentItem>> getPendingPayments() async {
    final response = await supabase
        .from('payments')
        .select('*, members!inner(name), memberships!inner(plan_type, duration_months)')
        .eq('status', 'pending')
        .order('paid_at', ascending: false);

    final rows = response as List<dynamic>;
    return rows.map((row) {
      final payment = Payment.fromJson(row as Map<String, dynamic>);
      final member = row['members'] as Map<String, dynamic>;
      final membership = row['memberships'] as Map<String, dynamic>;

      final durationMonths = membership['duration_months'] as int;
      final planType = membership['plan_type'] as String;

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

      return PendingPaymentItem(
        payment: payment,
        memberName: member['name'] as String,
        planLabel: '$duration $type',
      );
    }).toList();
  }

  /// Get a single pending payment by ID.
  Future<PendingPaymentItem> getPendingPaymentById(String id) async {
    final response = await supabase
        .from('payments')
        .select('*, members!inner(name), memberships!inner(plan_type, duration_months)')
        .eq('id', id)
        .single();

    final payment = Payment.fromJson(response);
    final member = response['members'] as Map<String, dynamic>;
    final membership = response['memberships'] as Map<String, dynamic>;

    final durationMonths = membership['duration_months'] as int;
    final planType = membership['plan_type'] as String;

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

    return PendingPaymentItem(
      payment: payment,
      memberName: member['name'] as String,
      planLabel: '$duration $type',
    );
  }

  /// Confirm a payment and activate its associated membership.
  Future<void> confirmPayment({
    required String paymentId,
    required String membershipId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final ownerId = supabase.auth.currentUser?.id;

    // 1. Update Payment
    await supabase.from('payments').update({
      'status': 'confirmed',
      'confirmed_at': now,
      'confirmed_by': ownerId,
    }).eq('id', paymentId);

    // 2. Activate Membership
    await supabase.from('memberships').update({
      'status': 'active',
      'payment_date': now,
    }).eq('id', membershipId);
  }

  /// Reject a pending payment.
  Future<void> rejectPayment({required String paymentId}) async {
    await supabase.from('payments').update({
      'status': 'rejected',
    }).eq('id', paymentId);
  }
}

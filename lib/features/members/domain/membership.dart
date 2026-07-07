import 'package:json_annotation/json_annotation.dart';

part 'membership.g.dart';

/// Membership status — matches the Postgres enum values exactly.
enum MembershipStatus {
  active,
  expired,
  @JsonValue('pending_renewal')
  pendingRenewal,
}

/// A membership record linking a member to a plan period.
///
/// Maps 1:1 to the `memberships` Supabase table.
@JsonSerializable()
class Membership {
  const Membership({
    required this.id,
    required this.memberId,
    required this.planType,
    required this.durationMonths,
    required this.priceCharged,
    required this.startDate,
    required this.dueDate,
    this.paymentDate,
    required this.status,
  });

  final String id;

  @JsonKey(name: 'member_id')
  final String memberId;

  @JsonKey(name: 'plan_type')
  final String planType;

  @JsonKey(name: 'duration_months')
  final int durationMonths;

  @JsonKey(name: 'price_charged')
  final double priceCharged;

  @JsonKey(name: 'start_date')
  final DateTime startDate;

  @JsonKey(name: 'due_date')
  final DateTime dueDate;

  @JsonKey(name: 'payment_date')
  final DateTime? paymentDate;

  final MembershipStatus status;

  factory Membership.fromJson(Map<String, dynamic> json) =>
      _$MembershipFromJson(json);
  Map<String, dynamic> toJson() => _$MembershipToJson(this);

  // ---- Computed helpers (read-only, no client-side status mutation) --------

  /// Days until due_date. Negative if overdue.
  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;

  /// Human-readable plan label for display (e.g. "Monthly Basic").
  String get planLabel {
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
    return '$duration $type';
  }
}

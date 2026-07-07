import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

enum PaymentStatus {
  pending,
  confirmed,
  rejected,
}

/// A payment transaction.
///
/// Maps 1:1 to the `payments` Supabase table.
@JsonSerializable()
class Payment {
  const Payment({
    required this.id,
    required this.memberId,
    required this.membershipId,
    required this.amount,
    this.utrNumber,
    this.screenshotUrl,
    required this.status,
    required this.paidAt,
    this.confirmedAt,
    this.confirmedBy,
  });

  final String id;

  @JsonKey(name: 'member_id')
  final String memberId;

  @JsonKey(name: 'membership_id')
  final String membershipId;

  final double amount;

  @JsonKey(name: 'utr_number')
  final String? utrNumber;

  @JsonKey(name: 'screenshot_url')
  final String? screenshotUrl;

  final PaymentStatus status;

  @JsonKey(name: 'paid_at')
  final DateTime paidAt;

  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;

  @JsonKey(name: 'confirmed_by')
  final String? confirmedBy;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

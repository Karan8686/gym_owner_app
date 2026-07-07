// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Membership _$MembershipFromJson(Map<String, dynamic> json) => Membership(
  id: json['id'] as String,
  memberId: json['member_id'] as String,
  planType: json['plan_type'] as String,
  durationMonths: (json['duration_months'] as num).toInt(),
  priceCharged: (json['price_charged'] as num).toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  dueDate: DateTime.parse(json['due_date'] as String),
  paymentDate: json['payment_date'] == null
      ? null
      : DateTime.parse(json['payment_date'] as String),
  status: $enumDecode(_$MembershipStatusEnumMap, json['status']),
);

Map<String, dynamic> _$MembershipToJson(Membership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member_id': instance.memberId,
      'plan_type': instance.planType,
      'duration_months': instance.durationMonths,
      'price_charged': instance.priceCharged,
      'start_date': instance.startDate.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'payment_date': instance.paymentDate?.toIso8601String(),
      'status': _$MembershipStatusEnumMap[instance.status]!,
    };

const _$MembershipStatusEnumMap = {
  MembershipStatus.active: 'active',
  MembershipStatus.expired: 'expired',
  MembershipStatus.pendingRenewal: 'pending_renewal',
};

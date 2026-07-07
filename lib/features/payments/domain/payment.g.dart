// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: json['id'] as String,
  memberId: json['member_id'] as String,
  membershipId: json['membership_id'] as String,
  amount: (json['amount'] as num).toDouble(),
  utrNumber: json['utr_number'] as String?,
  screenshotUrl: json['screenshot_url'] as String?,
  status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
  paidAt: DateTime.parse(json['paid_at'] as String),
  confirmedAt: json['confirmed_at'] == null
      ? null
      : DateTime.parse(json['confirmed_at'] as String),
  confirmedBy: json['confirmed_by'] as String?,
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'member_id': instance.memberId,
  'membership_id': instance.membershipId,
  'amount': instance.amount,
  'utr_number': instance.utrNumber,
  'screenshot_url': instance.screenshotUrl,
  'status': _$PaymentStatusEnumMap[instance.status]!,
  'paid_at': instance.paidAt.toIso8601String(),
  'confirmed_at': instance.confirmedAt?.toIso8601String(),
  'confirmed_by': instance.confirmedBy,
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.confirmed: 'confirmed',
  PaymentStatus.rejected: 'rejected',
};

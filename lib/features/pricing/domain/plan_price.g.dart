// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanPrice _$PlanPriceFromJson(Map<String, dynamic> json) => PlanPrice(
  id: json['id'] as String,
  planType: json['plan_type'] as String,
  durationMonths: (json['duration_months'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
);

Map<String, dynamic> _$PlanPriceToJson(PlanPrice instance) => <String, dynamic>{
  'id': instance.id,
  'plan_type': instance.planType,
  'duration_months': instance.durationMonths,
  'price': instance.price,
};

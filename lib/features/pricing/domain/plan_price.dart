import 'package:json_annotation/json_annotation.dart';

part 'plan_price.g.dart';

/// Price configurations for plans.
///
/// Maps 1:1 to the `plan_prices` Supabase table.
@JsonSerializable()
class PlanPrice {
  const PlanPrice({
    required this.id,
    required this.planType,
    required this.durationMonths,
    required this.price,
  });

  final String id;

  @JsonKey(name: 'plan_type')
  final String planType;

  @JsonKey(name: 'duration_months')
  final int durationMonths;

  final double price;

  factory PlanPrice.fromJson(Map<String, dynamic> json) =>
      _$PlanPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PlanPriceToJson(this);
}

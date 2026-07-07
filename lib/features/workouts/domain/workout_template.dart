import 'package:json_annotation/json_annotation.dart';

part 'workout_template.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? createdBy;
  final DateTime createdAt;

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutTemplateToJson(this);
}

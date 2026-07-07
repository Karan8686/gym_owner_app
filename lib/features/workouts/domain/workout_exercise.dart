import 'package:json_annotation/json_annotation.dart';

part 'workout_exercise.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    this.templateId,
    this.memberId,
    required this.dayOfWeek,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.notes,
    required this.sortOrder,
  });

  final String id;
  final String? templateId;
  final String? memberId;
  final String dayOfWeek;
  final String exerciseName;
  final int sets;
  final String reps;
  final int? restSeconds;
  final String? notes;
  final int sortOrder;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);
}

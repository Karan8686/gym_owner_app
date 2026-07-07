// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    WorkoutExercise(
      id: json['id'] as String,
      templateId: json['template_id'] as String?,
      memberId: json['member_id'] as String?,
      dayOfWeek: json['day_of_week'] as String,
      exerciseName: json['exercise_name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: json['reps'] as String,
      restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      sortOrder: (json['sort_order'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutExerciseToJson(WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'template_id': instance.templateId,
      'member_id': instance.memberId,
      'day_of_week': instance.dayOfWeek,
      'exercise_name': instance.exerciseName,
      'sets': instance.sets,
      'reps': instance.reps,
      'rest_seconds': instance.restSeconds,
      'notes': instance.notes,
      'sort_order': instance.sortOrder,
    };

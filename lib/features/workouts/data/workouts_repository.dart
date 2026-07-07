import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/workout_exercise.dart';
import '../domain/workout_template.dart';

final workoutsRepositoryProvider = Provider<WorkoutsRepository>((ref) {
  return WorkoutsRepository();
});

class TemplateWithCount {
  const TemplateWithCount({
    required this.template,
    required this.assignedCount,
  });

  final WorkoutTemplate template;
  final int assignedCount;
}

class WorkoutsRepository {
  WorkoutsRepository();

  final _uuid = const Uuid();

  /// Fetch all templates with their assigned members count.
  Future<List<TemplateWithCount>> getTemplates() async {
    // 1. Fetch templates
    final templatesResponse = await supabase
        .from('workout_templates')
        .select()
        .order('name', ascending: true);

    final templates = (templatesResponse as List<dynamic>)
        .map((t) => WorkoutTemplate.fromJson(t as Map<String, dynamic>))
        .toList();

    if (templates.isEmpty) return [];

    // 2. Fetch distinct member-template mappings from exercises to count assignments
    final exercisesResponse = await supabase
        .from('workout_exercises')
        .select('member_id, template_id')
        .not('member_id', 'is', null);

    final exerciseRows = exercisesResponse as List<dynamic>;

    // Map template_id -> Set of member_ids
    final countsMap = <String, Set<String>>{};
    for (final row in exerciseRows) {
      final tId = row['template_id'] as String?;
      final mId = row['member_id'] as String?;
      if (tId != null && mId != null) {
        countsMap.putIfAbsent(tId, () => {}).add(mId);
      }
    }

    return templates.map((template) {
      final assignedMembers = countsMap[template.id] ?? {};
      return TemplateWithCount(
        template: template,
        assignedCount: assignedMembers.length,
      );
    }).toList();
  }

  /// Get exercises for a template.
  Future<List<WorkoutExercise>> getTemplateExercises(String templateId) async {
    final response = await supabase
        .from('workout_exercises')
        .select()
        .eq('template_id', templateId)
        .isFilter('member_id', null)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get exercises currently assigned to a member.
  Future<List<WorkoutExercise>> getMemberExercises(String memberId) async {
    final response = await supabase
        .from('workout_exercises')
        .select()
        .eq('member_id', memberId)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new template with exercises.
  Future<void> createTemplate({
    required String name,
    required List<WorkoutExercise> exercises,
  }) async {
    final templateId = _uuid.v4();

    // 1. Insert template
    await supabase.from('workout_templates').insert({
      'id': templateId,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Insert exercises
    if (exercises.isNotEmpty) {
      final exerciseRows = exercises.map((e) {
        return {
          'id': _uuid.v4(),
          'template_id': templateId,
          'member_id': null,
          'day_of_week': e.dayOfWeek,
          'exercise_name': e.exerciseName,
          'sets': e.sets,
          'reps': e.reps,
          'rest_seconds': e.restSeconds,
          'notes': e.notes,
          'sort_order': e.sortOrder,
        };
      }).toList();

      await supabase.from('workout_exercises').insert(exerciseRows);
    }
  }

  /// Update an existing template name and replace all exercises.
  Future<void> updateTemplate({
    required String templateId,
    required String name,
    required List<WorkoutExercise> exercises,
  }) async {
    // 1. Update template name
    await supabase
        .from('workout_templates')
        .update({'name': name})
        .eq('id', templateId);

    // 2. Delete all existing template-specific exercises
    await supabase
        .from('workout_exercises')
        .delete()
        .eq('template_id', templateId)
        .isFilter('member_id', null);

    // 3. Insert new exercises
    if (exercises.isNotEmpty) {
      final exerciseRows = exercises.map((e) {
        return {
          'id': _uuid.v4(),
          'template_id': templateId,
          'member_id': null,
          'day_of_week': e.dayOfWeek,
          'exercise_name': e.exerciseName,
          'sets': e.sets,
          'reps': e.reps,
          'rest_seconds': e.restSeconds,
          'notes': e.notes,
          'sort_order': e.sortOrder,
        };
      }).toList();

      await supabase.from('workout_exercises').insert(exerciseRows);
    }
  }

  /// Delete template (automatically deletes exercises via cascade).
  Future<void> deleteTemplate(String templateId) async {
    await supabase.from('workout_templates').delete().eq('id', templateId);
  }

  /// Assign a template to a member by copying its exercises.
  Future<void> assignTemplateToMember({
    required String templateId,
    required String memberId,
  }) async {
    // 1. Delete all current exercises for this member
    await supabase.from('workout_exercises').delete().eq('member_id', memberId);

    // 2. Fetch exercises from template
    final templateExercises = await getTemplateExercises(templateId);

    // 3. Insert copied exercises for this member
    if (templateExercises.isNotEmpty) {
      final exerciseRows = templateExercises.map((e) {
        return {
          'id': _uuid.v4(),
          'template_id': templateId,
          'member_id': memberId,
          'day_of_week': e.dayOfWeek,
          'exercise_name': e.exerciseName,
          'sets': e.sets,
          'reps': e.reps,
          'rest_seconds': e.restSeconds,
          'notes': e.notes,
          'sort_order': e.sortOrder,
        };
      }).toList();

      await supabase.from('workout_exercises').insert(exerciseRows);
    }
  }

  /// Clear a member's assigned workout plan.
  Future<void> clearMemberWorkout(String memberId) async {
    await supabase.from('workout_exercises').delete().eq('member_id', memberId);
  }
}

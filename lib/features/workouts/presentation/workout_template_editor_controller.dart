import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workouts_repository.dart';
import '../domain/workout_exercise.dart';
import '../domain/workout_template.dart';
import 'workout_templates_controller.dart';

final workoutTemplateEditorControllerProvider = AsyncNotifierProviderFamily<
    WorkoutTemplateEditorController, WorkoutTemplateEditorState, String>(
  WorkoutTemplateEditorController.new,
);

class WorkoutTemplateEditorState {
  const WorkoutTemplateEditorState({
    this.template,
    required this.exercises,
    required this.isLoading,
  });

  final WorkoutTemplate? template;
  final List<WorkoutExercise> exercises;
  final bool isLoading;

  WorkoutTemplateEditorState copyWith({
    WorkoutTemplate? template,
    List<WorkoutExercise>? exercises,
    bool? isLoading,
  }) {
    return WorkoutTemplateEditorState(
      template: template ?? this.template,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkoutTemplateEditorController extends FamilyAsyncNotifier<
    WorkoutTemplateEditorState, String> {
  late final WorkoutsRepository _repo;

  @override
  FutureOr<WorkoutTemplateEditorState> build(String arg) async {
    _repo = ref.read(workoutsRepositoryProvider);

    if (arg == 'new') {
      return const WorkoutTemplateEditorState(
        template: null,
        exercises: [],
        isLoading: false,
      );
    }

    final templates = await _repo.getTemplates();
    final match = templates.firstWhere((t) => t.template.id == arg).template;
    final exercises = await _repo.getTemplateExercises(arg);

    return WorkoutTemplateEditorState(
      template: match,
      exercises: exercises,
      isLoading: false,
    );
  }

  void addLocalExercise(WorkoutExercise exercise) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = List<WorkoutExercise>.from(current.exercises)..add(exercise);
    state = AsyncValue.data(current.copyWith(exercises: updated));
  }

  void removeLocalExercise(String exerciseId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.exercises.where((e) => e.id != exerciseId).toList();
    state = AsyncValue.data(current.copyWith(exercises: updated));
  }

  Future<void> saveTemplate({
    required String name,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      if (arg == 'new') {
        await _repo.createTemplate(name: name, exercises: current.exercises);
      } else {
        await _repo.updateTemplate(
          templateId: arg,
          name: name,
          exercises: current.exercises,
        );
      }
      ref.invalidate(workoutTemplatesControllerProvider);
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<void> deleteTemplate() async {
    final current = state.valueOrNull;
    if (current == null || arg == 'new') return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      await _repo.deleteTemplate(arg);
      ref.invalidate(workoutTemplatesControllerProvider);
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }
}

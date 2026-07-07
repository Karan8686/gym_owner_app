import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../members/data/members_repository.dart';
import '../../members/domain/member.dart';
import '../../../core/config/supabase_config.dart';
import '../data/workouts_repository.dart';
import '../domain/workout_exercise.dart';
import 'assign_workout_controller.dart';

final memberWorkoutEditorControllerProvider = AsyncNotifierProviderFamily<
    MemberWorkoutEditorController, MemberWorkoutEditorState, String>(
  MemberWorkoutEditorController.new,
);

class MemberWorkoutEditorState {
  const MemberWorkoutEditorState({
    required this.member,
    required this.exercises,
    required this.isLoading,
  });

  final Member member;
  final List<WorkoutExercise> exercises;
  final bool isLoading;

  MemberWorkoutEditorState copyWith({
    Member? member,
    List<WorkoutExercise>? exercises,
    bool? isLoading,
  }) {
    return MemberWorkoutEditorState(
      member: member ?? this.member,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MemberWorkoutEditorController
    extends FamilyAsyncNotifier<MemberWorkoutEditorState, String> {
  late final MembersRepository _membersRepo;
  late final WorkoutsRepository _workoutsRepo;

  @override
  FutureOr<MemberWorkoutEditorState> build(String arg) async {
    _membersRepo = ref.read(membersRepositoryProvider);
    _workoutsRepo = ref.read(workoutsRepositoryProvider);

    final member = await _membersRepo.getMemberById(arg);
    final exercises = await _workoutsRepo.getMemberExercises(arg);

    return MemberWorkoutEditorState(
      member: member,
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

  Future<void> savePlan() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      // 1. Delete all current exercises for this member
      await _workoutsRepo.clearMemberWorkout(arg);

      // 2. Insert new exercises (copying them with member_id bound and template_id null)
      if (current.exercises.isNotEmpty) {
        final exerciseRows = current.exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          return {
            'id': const Uuid().v4(),
            'template_id': null,
            'member_id': arg,
            'day_of_week': e.dayOfWeek,
            'exercise_name': e.exerciseName,
            'sets': e.sets,
            'reps': e.reps,
            'rest_seconds': e.restSeconds,
            'notes': e.notes,
            'sort_order': idx,
          };
        }).toList();

        await supabase.from('workout_exercises').insert(exerciseRows);
      }

      // 3. Invalidate parent controller
      ref.invalidate(assignWorkoutControllerProvider(arg));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }
}

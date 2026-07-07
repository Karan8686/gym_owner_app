import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../members/data/members_repository.dart';
import '../../members/domain/member.dart';
import '../data/workouts_repository.dart';
import '../domain/workout_exercise.dart';

final assignWorkoutControllerProvider = AsyncNotifierProviderFamily<
    AssignWorkoutController, AssignWorkoutState, String>(
  AssignWorkoutController.new,
);

class AssignWorkoutState {
  const AssignWorkoutState({
    required this.member,
    required this.currentExercises,
    required this.templates,
    required this.isPickingTemplate,
    this.selectedTemplateId,
    required this.isLoading,
  });

  final Member member;
  final List<WorkoutExercise> currentExercises;
  final List<TemplateWithCount> templates;
  final bool isPickingTemplate;
  final String? selectedTemplateId;
  final bool isLoading;

  AssignWorkoutState copyWith({
    Member? member,
    List<WorkoutExercise>? currentExercises,
    List<TemplateWithCount>? templates,
    bool? isPickingTemplate,
    String? selectedTemplateId,
    bool? isLoading,
  }) {
    return AssignWorkoutState(
      member: member ?? this.member,
      currentExercises: currentExercises ?? this.currentExercises,
      templates: templates ?? this.templates,
      isPickingTemplate: isPickingTemplate ?? this.isPickingTemplate,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AssignWorkoutController
    extends FamilyAsyncNotifier<AssignWorkoutState, String> {
  late final MembersRepository _membersRepo;
  late final WorkoutsRepository _workoutsRepo;

  @override
  FutureOr<AssignWorkoutState> build(String arg) async {
    _membersRepo = ref.read(membersRepositoryProvider);
    _workoutsRepo = ref.read(workoutsRepositoryProvider);

    final member = await _membersRepo.getMemberById(arg);
    final exercises = await _workoutsRepo.getMemberExercises(arg);
    final templates = await _workoutsRepo.getTemplates();

    return AssignWorkoutState(
      member: member,
      currentExercises: exercises,
      templates: templates,
      isPickingTemplate: exercises.isEmpty,
      selectedTemplateId: templates.isNotEmpty ? templates.first.template.id : null,
      isLoading: false,
    );
  }

  void togglePickTemplate(bool pick) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isPickingTemplate: pick));
  }

  void selectTemplate(String templateId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(selectedTemplateId: templateId));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final member = await _membersRepo.getMemberById(arg);
      final exercises = await _workoutsRepo.getMemberExercises(arg);
      final templates = await _workoutsRepo.getTemplates();
      return AssignWorkoutState(
        member: member,
        currentExercises: exercises,
        templates: templates,
        isPickingTemplate: exercises.isEmpty,
        selectedTemplateId: templates.isNotEmpty ? templates.first.template.id : null,
        isLoading: false,
      );
    });
  }

  Future<void> assignSelectedTemplate() async {
    final current = state.valueOrNull;
    if (current == null || current.selectedTemplateId == null) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      await _workoutsRepo.assignTemplateToMember(
        templateId: current.selectedTemplateId!,
        memberId: arg,
      );
      final exercises = await _workoutsRepo.getMemberExercises(arg);
      state = AsyncValue.data(current.copyWith(
        currentExercises: exercises,
        isPickingTemplate: false,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<void> clearWorkout() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isLoading: true));

    try {
      await _workoutsRepo.clearMemberWorkout(arg);
      state = AsyncValue.data(current.copyWith(
        currentExercises: [],
        isPickingTemplate: true,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false));
      rethrow;
    }
  }
}

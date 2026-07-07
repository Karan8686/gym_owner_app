import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workouts_repository.dart';

final workoutTemplatesControllerProvider = AsyncNotifierProvider<
    WorkoutTemplatesController, List<TemplateWithCount>>(
  WorkoutTemplatesController.new,
);

class WorkoutTemplatesController extends AsyncNotifier<List<TemplateWithCount>> {
  late final WorkoutsRepository _repo;

  @override
  FutureOr<List<TemplateWithCount>> build() async {
    _repo = ref.read(workoutsRepositoryProvider);
    return _repo.getTemplates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getTemplates());
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteTemplate(id);
      return _repo.getTemplates();
    });
  }
}

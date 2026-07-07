import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/theme.dart';
import '../domain/workout_exercise.dart';
import 'member_workout_editor_controller.dart';

/// ──────────────────────────────────────────────
/// Member Workout Editor Screen — Screen 12.5 from GOAL.md.
///
/// Layout:
///   Top bar: ← "Edit Custom Plan"
///   Exercises List:
///     Row: Exercise Name, sets x reps, close/delete button
///   Button: "+ Add Exercise"
///   Fixed bottom: "Save Custom Plan"
/// ──────────────────────────────────────────────
class MemberWorkoutEditorScreen extends ConsumerStatefulWidget {
  const MemberWorkoutEditorScreen({
    required this.memberId,
    super.key,
  });

  final String memberId;

  @override
  ConsumerState<MemberWorkoutEditorScreen> createState() =>
      _MemberWorkoutEditorScreenState();
}

class _MemberWorkoutEditorScreenState
    extends ConsumerState<MemberWorkoutEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _save() async {
    try {
      await ref
          .read(memberWorkoutEditorControllerProvider(widget.memberId).notifier)
          .savePlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom plan saved successfully.'),
            backgroundColor: AppColors.inkPrimary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save plan. Please try again.'),
            backgroundColor: AppColors.signal,
          ),
        );
      }
    }
  }

  void _showAddExerciseDialog() {
    final exerciseFormKey = GlobalKey<FormState>();
    String exerciseName = '';
    String dayOfWeek = 'Monday';
    int sets = 3;
    String reps = '10';
    int? restSeconds;
    String? notes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.containerPadding,
            left: AppSpacing.containerPadding,
            right: AppSpacing.containerPadding,
            top: AppSpacing.containerPadding,
          ),
          child: Form(
            key: exerciseFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ADD EXERCISE',
                    style: AppText.label.copyWith(color: AppColors.inkSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  
                  // Exercise Name
                  TextFormField(
                    autofocus: true,
                    style: AppText.bodyLg,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name',
                      hintText: 'e.g. Barbell Squat',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    onSaved: (val) => exerciseName = val!.trim(),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),

                  // Day of Week Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: dayOfWeek,
                    items: const [
                      DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                      DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                      DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                      DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                      DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                      DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                      DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
                    ],
                    onChanged: (val) => dayOfWeek = val!,
                    decoration: const InputDecoration(labelText: 'Day of Week'),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),

                  // Sets and Reps Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sets'),
                          initialValue: '3',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            final s = int.tryParse(val);
                            if (s == null || s <= 0) return 'Invalid';
                            return null;
                          },
                          onSaved: (val) => sets = int.parse(val!),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            hintText: 'e.g. 10 or 8-12',
                          ),
                          initialValue: '10',
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                          onSaved: (val) => reps = val!.trim(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackMd),

                  // Rest Seconds & Notes
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rest (seconds)'),
                          onSaved: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              restSeconds = int.tryParse(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onSaved: (val) => notes = val?.trim(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Add button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (exerciseFormKey.currentState!.validate()) {
                          exerciseFormKey.currentState!.save();
                          final newEx = WorkoutExercise(
                            id: const Uuid().v4(),
                            dayOfWeek: dayOfWeek,
                            exerciseName: exerciseName,
                            sets: sets,
                            reps: reps,
                            restSeconds: restSeconds,
                            notes: notes,
                            sortOrder: 0,
                          );
                          ref
                              .read(memberWorkoutEditorControllerProvider(widget.memberId).notifier)
                              .addLocalExercise(newEx);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inkPrimary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cornerRadius),
                        ),
                      ),
                      child: const Text('ADD TO LIST'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(memberWorkoutEditorControllerProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Custom Plan',
          style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: editorState.when(
        data: (stateVal) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.containerPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'MEMBER ROUTINE FOR: ${stateVal.member.name.toUpperCase()}',
                          style: AppText.label.copyWith(color: AppColors.inkSecondary, letterSpacing: 1),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),

                        // ---- Exercises list ---------------------------------
                        Text(
                          'EXERCISES',
                          style: AppText.label.copyWith(color: AppColors.inkSecondary, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: AppSpacing.stackSm),

                        if (stateVal.exercises.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(
                              'No exercises added yet.\nTap "+ Add Exercise" below to build custom plan.',
                              style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          _buildExerciseList(stateVal.exercises),

                        const SizedBox(height: AppSpacing.stackMd),

                        // ---- Add Exercise Button -----------------------------
                        OutlinedButton.icon(
                          onPressed: _showAddExerciseDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('ADD EXERCISE'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Fixed Bottom Save Button ---------------------------------
              _buildSaveButton(stateVal.isLoading),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.inkPrimary,
            strokeWidth: 2,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load member custom plan.',
            style: AppText.bodySm.copyWith(color: AppColors.signal),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(List<WorkoutExercise> exercises) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == exercises.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exerciseName,
                        style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.dayOfWeek} • ${item.notes ?? ""}'.trim(),
                        style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${item.sets}x${item.reps}',
                      style: AppText.dataSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.inkSecondary),
                      onPressed: () {
                        ref
                            .read(memberWorkoutEditorControllerProvider(widget.memberId).notifier)
                            .removeLocalExercise(item.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton(bool isSaving) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inkPrimary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.inkPrimary.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : Text(
                    'SAVE CUSTOM PLAN',
                    style: AppText.bodyLg.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

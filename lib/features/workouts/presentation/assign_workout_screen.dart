import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import 'assign_workout_controller.dart';

/// ──────────────────────────────────────────────
/// Assign Workout Screen — Screen 13 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: ← member name (e.g. Alex Rodriguez)
///   If member has plan:
///     Shows list of current exercises, EDIT CUSTOM PLAN, ASSIGN FROM TEMPLATE, CLEAR ROUTINE.
///   If picking template:
///     "CHOOSE A TEMPLATE" Segmented radio list.
///     "Or Build Custom Plan" Button.
///     Fixed bottom "Assign Plan" Action.
/// ──────────────────────────────────────────────
class AssignWorkoutScreen extends ConsumerWidget {
  const AssignWorkoutScreen({
    required this.memberId,
    super.key,
  });

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignWorkoutControllerProvider(memberId));

    return state.when(
      data: (val) {
        final member = val.member;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              member.name,
              style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          body: val.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.inkPrimary,
                    strokeWidth: 2,
                  ),
                )
              : val.isPickingTemplate
                  ? _buildTemplatePicker(context, ref, val)
                  : _buildCurrentPlanView(context, ref, val),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.inkPrimary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Failed to load member workout plan.',
            style: AppText.bodySm.copyWith(color: AppColors.signal),
          ),
        ),
      ),
    );
  }

  // ---- Template Picker View ----
  Widget _buildTemplatePicker(
    BuildContext context,
    WidgetRef ref,
    AssignWorkoutState val,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CHOOSE A TEMPLATE',
                  style: AppText.label.copyWith(
                    color: AppColors.inkSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),

                if (val.templates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      'No templates created yet.\nTap "+ New Template" in Workouts library to add templates.',
                      style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: val.templates.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final t = row.template;
                        final isLast = index == val.templates.length - 1;
                        final isSelected = val.selectedTemplateId == t.id;

                        return InkWell(
                          onTap: () {
                            ref
                                .read(assignWorkoutControllerProvider(memberId).notifier)
                                .selectTemplate(t.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: AppText.bodyLg.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.inkPrimary : AppColors.border,
                                      width: isSelected ? 6 : 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: AppSpacing.stackLg),

                // Or Build Custom Plan Button
                OutlinedButton(
                  onPressed: () => context.push('/members/$memberId/workout/edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OR BUILD CUSTOM PLAN',
                    style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Button
        if (val.templates.isNotEmpty)
          _buildActionButton(
            label: 'ASSIGN PLAN',
            onTap: () => ref
                .read(assignWorkoutControllerProvider(memberId).notifier)
                .assignSelectedTemplate(),
          ),
      ],
    );
  }

  // ---- Current Plan List View ----
  Widget _buildCurrentPlanView(
    BuildContext context,
    WidgetRef ref,
    AssignWorkoutState val,
  ) {
    // Group exercises by day of week
    final daysOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final grouped = <String, List<dynamic>>{};
    for (final ex in val.currentExercises) {
      grouped.putIfAbsent(ex.dayOfWeek, () => []).add(ex);
    }

    final sortedDays = daysOrder.where((d) => grouped.containsKey(d)).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CURRENT ROUTINE',
                  style: AppText.label.copyWith(
                    color: AppColors.inkSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),

                ...sortedDays.map((day) {
                  final list = grouped[day]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day.toUpperCase(),
                          style: AppText.label.copyWith(color: AppColors.inkPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: list.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ex = entry.value;
                            final isLast = idx == list.length - 1;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.exerciseName,
                                          style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        if (ex.notes != null && ex.notes!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            ex.notes!,
                                            style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${ex.sets}x${ex.reps}',
                                    style: AppText.dataSm.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                    ],
                  );
                }),

                const SizedBox(height: AppSpacing.stackMd),

                // Edit Custom Plan
                OutlinedButton(
                  onPressed: () => context.push('/members/$memberId/workout/edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'EDIT CUSTOM PLAN',
                    style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.stackSm),

                // Assign from Template
                OutlinedButton(
                  onPressed: () => ref
                      .read(assignWorkoutControllerProvider(memberId).notifier)
                      .togglePickTemplate(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'ASSIGN FROM TEMPLATE',
                    style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: AppSpacing.stackSm),

                // Clear Plan (destructive)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Plan?'),
                        content: const Text(
                          'Are you sure you want to remove all workouts for this member? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL', style: TextStyle(color: AppColors.inkSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('CLEAR', style: TextStyle(color: AppColors.signal)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      ref
                          .read(assignWorkoutControllerProvider(memberId).notifier)
                          .clearWorkout();
                    }
                  },
                  child: Text(
                    'CLEAR ROUTINE',
                    style: AppText.label.copyWith(color: AppColors.signal, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
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
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inkPrimary,
              foregroundColor: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
            ),
            child: Text(
              label,
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

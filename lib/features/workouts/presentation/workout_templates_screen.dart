import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import 'workout_templates_controller.dart';

/// ──────────────────────────────────────────────
/// Workout Template Library — Screen 11 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: ← "Workout Templates"
///   Rows:
///     Template Name (e.g. Strength & Conditioning Alpha)
///     "X members assigned"
///   FAB: "+ New Template"
/// ──────────────────────────────────────────────
class WorkoutTemplatesScreen extends ConsumerWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutTemplatesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Workout Templates',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.inkPrimary,
          onRefresh: () => ref.read(workoutTemplatesControllerProvider.notifier).refresh(),
          child: state.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No templates created yet.\nTap "+ New Template" to add one.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(
                  left: AppSpacing.gutter,
                  right: AppSpacing.gutter,
                  top: AppSpacing.stackMd,
                  bottom: 92, // scroll padding for floating navbar
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackSm),
                itemBuilder: (context, index) {
                  final row = items[index];
                  final t = row.template;

                  return GestureDetector(
                    onTap: () => context.push('/settings/workouts/${t.id}'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(cornerRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${row.assignedCount} members assigned',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.inkSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.inkPrimary,
                strokeWidth: 2,
              ),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load workout templates.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextButton(
                    onPressed: () => ref.read(workoutTemplatesControllerProvider.notifier).refresh(),
                    child: Text('Retry', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.inkPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Clear the floating navbar
        child: ElevatedButton.icon(
          onPressed: () => context.push('/settings/workouts/new'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.inkPrimary,
            foregroundColor: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackSm,
            ),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            'NEW TEMPLATE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}

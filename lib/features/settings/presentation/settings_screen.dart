import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final owner = authState.valueOrNull;

    const ownerName = 'Sarah Jenkins';
    final ownerEmail = owner?.email ?? 'gym@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header Section ---------------------------------------------
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                top: AppSpacing.stackLg,
                left: AppSpacing.gutter,
                right: AppSpacing.gutter,
              ),
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apex Athletics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.unit),
                  Text(
                    'Owner: $ownerName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ownerEmail,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),

            // ---- Settings List ----------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 92), // clear floating navbar
                children: [
                  const SizedBox(height: AppSpacing.stackMd),
                  _buildMenuSection([
                    _buildMenuItem(
                      context,
                      title: 'Plan & Pricing Settings',
                      onTap: () => context.push(AppRoutes.planPricing),
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Workout Templates',
                      onTap: () => context.push(AppRoutes.workoutTemplates),
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Revenue & Analytics',
                      onTap: () => context.push(AppRoutes.analytics),
                      isLast: true,
                    ),
                  ]),



                  const SizedBox(height: AppSpacing.stackLg),
                  
                  // ---- Log Out Button ---------------------------------------
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(cornerRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      title: Text(
                        'Log Out',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.signal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.inkSecondary,
          size: 20,
        ),
      ),
    );
  }
}

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
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apex Athletics',
                    style: AppText.display.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.unit),
                  Text(
                    'Owner: $ownerName',
                    style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ownerEmail,
                    style: AppText.dataSm.copyWith(color: AppColors.inkSecondary),
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
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.stackMd),
                  _buildMenuSection([
                    _buildMenuItem(
                      context,
                      title: 'Gym Details',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Notification Preferences',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Manage Staff Access',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Export Member Data',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.stackLg),
                  
                  // ---- Log Out Button ---------------------------------------
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border.symmetric(
                        horizontal: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      title: Text(
                        'Log Out',
                        style: AppText.bodyLg.copyWith(
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: AppText.bodyLg),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.inkSecondary,
          size: 20,
        ),
      ),
    );
  }
}

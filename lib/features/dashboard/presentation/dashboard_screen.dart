import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/router/app_router.dart';
import '../data/dashboard_repository.dart';
import 'dashboard_controller.dart';

/// ──────────────────────────────────────────────
/// Dashboard / Home screen — Screen 2 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: date + "FitTrack Owner" + notification bell
///   Metrics row: ACTIVE | EXPIRING SOON | EXPIRED
///   Renewals-due list
///   FAB: + ADD MEMBER
///   Bottom nav: DASHBOARD | MEMBERS | MORE
/// ──────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top App Bar ------------------------------------------------
            _buildTopBar(context),

            // ---- Content ----------------------------------------------------
            Expanded(
              child: dashState.when(
                data: (data) => _buildContent(context, ref, data),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.inkPrimary,
                    strokeWidth: 2,
                  ),
                ),
                error: (error, _) => _buildError(ref, error),
              ),
            ),
          ],
        ),
      ),

      // ---- FAB: + ADD MEMBER -----------------------------------------------
      floatingActionButton: _buildFab(context),
    );
  }

  // --------------------------------------------------------------------------
  // Top bar
  // --------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    final today = DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Left: date + title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  today,
                  style: AppText.label.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'FitTrack Owner',
                  style: AppText.headline.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          // Right: notification bell
          IconButton(
            onPressed: () {
              context.push(AppRoutes.settings);
            },
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.inkPrimary,
              size: 24,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Main content: stats + renewals list with pull-to-refresh
  // --------------------------------------------------------------------------
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DashboardData data,
  ) {
    return RefreshIndicator(
      color: AppColors.inkPrimary,
      onRefresh: () =>
          ref.read(dashboardControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          top: AppSpacing.stackMd,
          bottom: 180,
        ),
        children: [
          // ---- Metrics row --------------------------------------------------
          _buildMetricsRow(data.stats),

          const SizedBox(height: AppSpacing.stackLg),

          // ---- Renewals due header ------------------------------------------
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.unit,
              bottom: AppSpacing.stackSm,
            ),
            child: Text(
              'RENEWALS DUE',
              style: AppText.label.copyWith(color: AppColors.inkSecondary),
            ),
          ),

          // ---- Renewals list ------------------------------------------------
          if (data.renewalsDue.isEmpty)
            _buildEmptyState('No renewals due.')
          else
            _buildRenewalsList(context, data.renewalsDue),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Metrics row: ACTIVE | EXPIRING SOON | EXPIRED
  // --------------------------------------------------------------------------
  Widget _buildMetricsRow(DashboardStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildMetricCell(
              value: stats.activeCount.toString(),
              label: 'ACTIVE',
              valueColor: AppColors.inkPrimary,
              showRightBorder: true,
            ),
            _buildMetricCell(
              value: stats.expiringSoonCount.toString(),
              label: 'EXPIRING\nSOON',
              valueColor: AppColors.inkPrimary,
              showRightBorder: true,
            ),
            _buildMetricCell(
              value: stats.expiredCount.toString(),
              label: 'EXPIRED',
              valueColor: AppColors.signal, // red — destructive state
              showRightBorder: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({
    required String value,
    required String label,
    required Color valueColor,
    required bool showRightBorder,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          border: showRightBorder
              ? const Border(right: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppText.display.copyWith(
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              label,
              style: AppText.label.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Renewals-due list
  // --------------------------------------------------------------------------
  Widget _buildRenewalsList(
    BuildContext context,
    List<RenewalDueItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return _buildRenewalRow(context, item, showBottomBorder: !isLast);
        }),
      ),
    );
  }

  Widget _buildRenewalRow(
    BuildContext context,
    RenewalDueItem item, {
    required bool showBottomBorder,
  }) {
    // ≤ 2 days → signal red, else inkPrimary (per Stitch mockup)
    final daysColor =
        item.daysRemaining <= 2 ? AppColors.signal : AppColors.inkPrimary;

    final daysText = item.daysRemaining == 1
        ? '1 day'
        : '${item.daysRemaining} days';

    return GestureDetector(
      onTap: () {
        context.push('/members/${item.memberId}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: AppSpacing.stackMd,
        ),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            // Left: name + plan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.memberName, style: AppText.bodyLg),
                  Text(
                    item.planLabel,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Right: days remaining (monospace)
            Text(
              daysText,
              style: AppText.dataLg.copyWith(color: daysColor),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Empty state
  // --------------------------------------------------------------------------
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Center(
        child: Text(
          message,
          style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Error state
  // --------------------------------------------------------------------------
  Widget _buildError(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load dashboard. Check your connection and try again.",
              style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
              child: Text(
                'Retry',
                style: AppText.label.copyWith(color: AppColors.inkPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // FAB: + ADD MEMBER
  // --------------------------------------------------------------------------
  Widget _buildFab(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 110),
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.addMember),
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
          'ADD MEMBER',
          style: AppText.label.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }

}

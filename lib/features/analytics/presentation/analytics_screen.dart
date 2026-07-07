import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import 'analytics_controller.dart';
import '../data/analytics_repository.dart';

/// ──────────────────────────────────────────────
/// Revenue & Analytics Screen — Screen 14 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: ← "Revenue"
///   Monthly summary:
///     ₹1,42,500 (Monospace display font)
///     "+12% vs last month" (labeled indicator)
///   6-month Bar Chart
///   Plan Breakdown Segment (Weight vs. Cardio)
/// ──────────────────────────────────────────────
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Revenue',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: RefreshIndicator(
        color: AppColors.inkPrimary,
        onRefresh: () => ref.read(analyticsControllerProvider.notifier).refresh(),
        child: state.when(
          data: (stats) {
            final maxRevenue = stats.monthlyHistory.map((h) => h.revenue).fold<double>(0, math.max);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Summary Card -----------------------------------------
                  _buildSummarySection(stats, currencyFormatter),

                  const SizedBox(height: AppSpacing.stackLg),

                  // ---- Chart Card -------------------------------------------
                  _buildChartSection(stats, maxRevenue),

                  const SizedBox(height: AppSpacing.stackLg),

                  // ---- Breakdown Segment -------------------------------------
                  _buildBreakdownSection(stats, currencyFormatter),
                ],
              ),
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
                  'Failed to load analytics statistics.',
                  style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                TextButton(
                  onPressed: () => ref.read(analyticsControllerProvider.notifier).refresh(),
                  child: Text('Retry', style: AppText.label.copyWith(color: AppColors.inkPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(dynamic stats, NumberFormat formatter) {
    final pct = stats.revenueChangePercentage;
    final isPositive = pct >= 0;
    final color = isPositive ? const Color(0xFF107C41) : AppColors.signal;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatter.format(stats.currentMonthRevenue),
            style: AppText.display.copyWith(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              fontSize: 32,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'This Month',
                style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${pct.toStringAsFixed(0)}%',
                style: AppText.label.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                'vs last month',
                style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(dynamic stats, double maxRevenue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '6-MONTH REVENUE HISTORY',
            style: AppText.label.copyWith(color: AppColors.inkSecondary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Chart Canvas
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Dashed Grid Lines (in background)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Row(
                      children: List.generate(40, (i) {
                        return Expanded(
                          child: Container(
                            height: 1,
                            color: i % 2 == 0 ? AppColors.border : Colors.transparent,
                          ),
                        );
                      }),
                    );
                  }),
                ),

                // Vertical Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: stats.monthlyHistory.map<Widget>((MonthlyRevenue m) {
                    final fraction = maxRevenue > 0 ? (m.revenue / maxRevenue) : 0.0;
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: fraction == 0 ? 0.02 : fraction,
                              child: Container(
                                width: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.inkPrimary,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.monthLabel.toUpperCase(),
                          style: AppText.label.copyWith(fontSize: 10, color: AppColors.inkSecondary),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(dynamic stats, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PLAN BREAKDOWN',
          style: AppText.label.copyWith(color: AppColors.inkSecondary, letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildBreakdownRow(
                title: 'Weight Only',
                subtitle: '${stats.weightPlanCount} active members',
                value: formatter.format(stats.weightPlanRevenue),
                showBorder: true,
              ),
              _buildBreakdownRow(
                title: 'Cardio + Weight',
                subtitle: '${stats.cardioPlanCount} active members',
                value: formatter.format(stats.cardioPlanRevenue),
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required String value,
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 16),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppText.bodySm.copyWith(color: AppColors.inkSecondary)),
            ],
          ),
          Text(
            value,
            style: AppText.bodyLg.copyWith(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

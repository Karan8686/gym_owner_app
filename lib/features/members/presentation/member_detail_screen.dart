import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../domain/membership.dart';
import 'member_detail_controller.dart';

/// ──────────────────────────────────────────────
/// Member Detail — Screen 4 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   App bar: ← "Member Detail"
///   Header card: name, phone, days left
///   MEMBERSHIP section: plan, duration, start/due dates
///   PAYMENT HISTORY section: date | amount | status
///   WORKOUT PLAN section: "View / Edit Plan" → chevron
///   Bottom bar: Edit Member | Renew Membership
/// ──────────────────────────────────────────────
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(memberDetailControllerProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Member Detail', style: AppText.headline),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.inkPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: detailState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.inkPrimary,
            strokeWidth: 2,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load member details.",
                style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextButton(
                onPressed: () => ref
                    .read(memberDetailControllerProvider(memberId).notifier)
                    .refresh(),
                child: Text('Retry',
                    style:
                        AppText.label.copyWith(color: AppColors.inkPrimary)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  // --------------------------------------------------------------------------
  // Content
  // --------------------------------------------------------------------------
  Widget _buildContent(BuildContext context, MemberDetailData data) {
    final membership = data.latestMembership;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        // ---- Header card ----------------------------------------------------
        _buildHeaderCard(data, membership),
        const SizedBox(height: AppSpacing.stackMd),

        // ---- Membership section ---------------------------------------------
        if (membership != null) ...[
          _buildSection(
            title: 'MEMBERSHIP',
            children: [
              _buildDetailRow('Plan', membership.planLabel, isData: false),
              _buildDetailRow(
                'Duration',
                '${membership.durationMonths} Months',
                isData: true,
              ),
              _buildDetailRow(
                'Start Date',
                _formatDate(membership.startDate),
                isData: true,
              ),
              _buildDetailRow(
                'Due Date',
                _formatDate(membership.dueDate),
                isData: true,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
        ],

        // ---- Payment history ------------------------------------------------
        _buildSection(
          title: 'PAYMENT HISTORY',
          children: data.payments.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                      vertical: 12,
                    ),
                    child: Text(
                      'No payments recorded.',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ]
              : data.payments
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildPaymentRow(
                        entry.value,
                        isLast: entry.key == data.payments.length - 1,
                      ),
                    )
                    .toList(),
        ),
        const SizedBox(height: AppSpacing.stackMd),

        // ---- Workout plan ---------------------------------------------------
        _buildSection(
          title: 'WORKOUT PLAN',
          children: [
            GestureDetector(
              onTap: () => context.push('/members/$memberId/assign-workout'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('View / Edit Plan', style: AppText.bodySm),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Header card: name, phone, days left
  // --------------------------------------------------------------------------
  Widget _buildHeaderCard(MemberDetailData data, Membership? membership) {
    final daysLeft = membership?.daysRemaining;
    final daysColor = (daysLeft != null && daysLeft <= 7)
        ? AppColors.signal
        : AppColors.inkPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.inkPrimary.withValues(alpha: 0.1),
            backgroundImage: (data.member.photoUrl != null && data.member.photoUrl!.isNotEmpty)
                ? NetworkImage(data.member.photoUrl!)
                : null,
            child: (data.member.photoUrl == null || data.member.photoUrl!.isEmpty)
                ? const Icon(Icons.person, color: AppColors.inkPrimary, size: 32)
                : null,
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.member.name, style: AppText.display),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  data.member.phoneNo,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (daysLeft != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  daysLeft.toString(),
                  style: AppText.dataLg.copyWith(color: daysColor),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'DAYS LEFT',
                  style: AppText.label.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Section card with header
  // --------------------------------------------------------------------------
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header with light bg
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.stackSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: const Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              title,
              style: AppText.label.copyWith(color: AppColors.inkSecondary),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Detail row: label + value
  // --------------------------------------------------------------------------
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isData = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.bodySm),
          Text(
            value,
            style: isData
                ? AppText.dataSm
                : AppText.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Payment row: date | amount | status
  // --------------------------------------------------------------------------
  Widget _buildPaymentRow(PaymentSummary payment, {bool isLast = false}) {
    final statusColor = payment.status == 'rejected'
        ? AppColors.signal
        : AppColors.inkPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            child: Text(
              _formatDate(payment.paidAt),
              style: AppText.dataSm,
            ),
          ),
          // Amount
          Expanded(
            child: Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: AppText.dataSm,
              textAlign: TextAlign.right,
            ),
          ),
          // Status
          Expanded(
            child: Text(
              _capitalize(payment.status),
              style: AppText.label.copyWith(color: statusColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom actions: Edit Member | Renew Membership
  // --------------------------------------------------------------------------
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Edit Member
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/members/$memberId/edit'),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border:
                        Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Text(
                    'Edit Member',
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Renew Membership
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/members/$memberId/renew'),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  color: AppColors.background,
                  child: Text(
                    'Renew Membership',
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

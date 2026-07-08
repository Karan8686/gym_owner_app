import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../domain/membership.dart';
import '../data/members_repository.dart';
import 'member_detail_controller.dart';
import 'member_list_controller.dart';

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

  Future<void> _removeMember(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
            side: const BorderSide(color: AppColors.border),
          ),
          backgroundColor: AppColors.surface,
          title: Text('Remove Member', style: AppText.headline),
          content: Text(
            'Are you sure you want to remove this member? This action is permanent and deletes all membership and payment logs.',
            style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppText.label.copyWith(color: AppColors.inkSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Remove',
                style: AppText.label.copyWith(color: AppColors.signal),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.inkPrimary),
        ),
      );

      await ref.read(membersRepositoryProvider).deleteMember(memberId);
      ref.invalidate(allMembersProvider);

      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        context.go('/members');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to remove member. Check your connection."),
            backgroundColor: AppColors.signal,
          ),
        );
      }
    }
  }

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
        actions: [
          IconButton(
            onPressed: () => _removeMember(context, ref),
            icon: const Icon(Icons.delete_outline, color: AppColors.signal),
          ),
        ],
      ),
      body: detailState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.inkPrimary,
            strokeWidth: 2,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  error.toString(),
                  style: AppText.bodySm.copyWith(color: AppColors.signal),
                  textAlign: TextAlign.center,
                ),
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
        _buildHeaderCard(context, data, membership),
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
              ),
              _buildDetailRow(
                'Fees Paid',
                '₹${membership.priceCharged.toStringAsFixed(2)}',
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
  Widget _buildHeaderCard(BuildContext context, MemberDetailData data, Membership? membership) {
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inkPrimary.withValues(alpha: 0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: (data.member.photoUrl != null && data.member.photoUrl!.isNotEmpty)
                ? Image.network(data.member.photoUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      data.member.name.isNotEmpty ? data.member.name[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.inkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.member.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.member.phoneNo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: daysColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'DAYS LEFT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w700,
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
                  color: AppColors.inkPrimary,
                  child: Text(
                    'Renew Membership',
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
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

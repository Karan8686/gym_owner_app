import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/router/app_router.dart';
import 'pending_payments_controller.dart';
import '../data/payments_repository.dart';

/// ──────────────────────────────────────────────
/// Pending Payments List — Screen 8 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: ← "Pending Payments"
///   Payment Rows:
///     Left: Member name, Amount (monospace), UTR Number, Time submitted
///     Right: Stacked "CONFIRM" (black bg) & "REJECT" (outlined red) buttons
///   Empty State: "No pending payments."
///   Bottom nav
/// ──────────────────────────────────────────────
class PendingPaymentsScreen extends ConsumerWidget {
  const PendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(pendingPaymentsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.go(AppRoutes.memberList),
        ),
        title: Text(
          'Pending Payments',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: paymentsState.when(
                data: (items) => _buildList(context, ref, items),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.inkPrimary,
                    strokeWidth: 2,
                  ),
                ),
                error: (err, _) => _buildError(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<PendingPaymentItem> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Text(
            'No pending payments.',
            style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.inkPrimary,
      onRefresh: () => ref.read(pendingPaymentsControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          top: AppSpacing.stackMd,
          bottom: 92,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackSm),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildPaymentCard(context, ref, item);
        },
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    WidgetRef ref,
    PendingPaymentItem item,
  ) {
    final payment = item.payment;
    final timeStr = _formatTimestamp(payment.paidAt);

    return GestureDetector(
      onTap: () => context.push('/payments/pending/${payment.id}/verify'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Avatar (matching MemberCard style)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inkPrimary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  item.memberName.isNotEmpty ? item.memberName[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.inkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Middle: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.memberName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  if (payment.utrNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'UPI: ${payment.utrNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Action buttons
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(pendingPaymentsControllerProvider.notifier)
                        .confirmPayment(
                          paymentId: payment.id,
                          membershipId: payment.membershipId,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkPrimary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: Text(
                      'CONFIRM',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(pendingPaymentsControllerProvider.notifier)
                        .rejectPayment(paymentId: payment.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.signal,
                      side: const BorderSide(color: AppColors.signal),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 14),
                    label: Text(
                      'REJECT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.signal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load pending payments. Check connection and try again.",
              style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(
              onPressed: () => ref.read(pendingPaymentsControllerProvider.notifier).refresh(),
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



  String _formatTimestamp(DateTime paidAt) {
    final now = DateTime.now();
    final difference = now.difference(paidAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      if (paidAt.day == now.day) {
        return 'Today, ${DateFormat('h:mm a').format(paidAt)}';
      } else {
        return 'Yesterday, ${DateFormat('h:mm a').format(paidAt)}';
      }
    } else {
      return DateFormat('MMM d, h:mm a').format(paidAt);
    }
  }
}

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
          onPressed: () => context.go(AppRoutes.dashboard),
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
            // Left details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.memberName,
                    style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.unit),
                  Text(
                    '₹${payment.amount.toStringAsFixed(2)}',
                    style: AppText.dataLg.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (payment.utrNumber != null) ...[
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      'UPI: ${payment.utrNumber}',
                      style: AppText.dataSm.copyWith(color: AppColors.inkSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.unit),
                  Text(
                    timeStr,
                    style: AppText.label.copyWith(color: AppColors.inkSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Right action buttons
            const SizedBox(width: AppSpacing.gutter),
            SizedBox(
              width: 96,
              child: Column(
                children: [
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(pendingPaymentsControllerProvider.notifier)
                          .confirmPayment(
                            paymentId: payment.id,
                            membershipId: payment.membershipId,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inkPrimary,
                        foregroundColor: AppColors.surface,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: AppText.label.copyWith(
                          color: AppColors.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.unit * 2),
                  // Reject Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(pendingPaymentsControllerProvider.notifier)
                          .rejectPayment(paymentId: payment.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.signal,
                        side: const BorderSide(color: AppColors.signal),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'REJECT',
                        style: AppText.label.copyWith(
                          color: AppColors.signal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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

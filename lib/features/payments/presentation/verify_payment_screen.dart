import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../data/payments_repository.dart';
import 'pending_payments_controller.dart';

class VerifyPaymentScreen extends ConsumerStatefulWidget {
  const VerifyPaymentScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  ConsumerState<VerifyPaymentScreen> createState() => _VerifyPaymentScreenState();
}

class _VerifyPaymentScreenState extends ConsumerState<VerifyPaymentScreen> {
  bool _isLoading = false;
  String? _error;
  PendingPaymentItem? _item;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      final item = await ref.read(paymentsRepositoryProvider).getPendingPaymentById(widget.paymentId);
      if (mounted) {
        setState(() {
          _item = item;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load payment details.";
        });
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_item == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(pendingPaymentsControllerProvider.notifier).confirmPayment(
            paymentId: _item!.payment.id,
            membershipId: _item!.payment.membershipId,
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to confirm payment.";
      });
    }
  }

  Future<void> _rejectPayment() async {
    if (_item == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(pendingPaymentsControllerProvider.notifier).rejectPayment(
            paymentId: _item!.payment.id,
          );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to reject payment.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verify',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextButton(
                onPressed: _loadPaymentDetails,
                child: Text('Retry', style: AppText.label.copyWith(color: AppColors.inkPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    if (_item == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.inkPrimary,
          strokeWidth: 2,
        ),
      );
    }

    final payment = _item!.payment;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Member Context -----------------------------------------
                Text(_item!.memberName, style: AppText.display),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  _item!.planLabel,
                  style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                ),

                const SizedBox(height: AppSpacing.stackMd),
                const Divider(color: AppColors.border, thickness: 1),
                const SizedBox(height: AppSpacing.stackMd),

                // ---- Data Rows ----------------------------------------------
                _buildDataRow('Amount', '₹${payment.amount.toStringAsFixed(2)}', isMonospace: true),
                const SizedBox(height: AppSpacing.stackSm),
                _buildDataRow('UPI Reference Number', payment.utrNumber ?? 'N/A', isMonospace: true),
                const SizedBox(height: AppSpacing.stackSm),
                _buildDataRow(
                  'Submitted At',
                  DateFormat('MMM d, yyyy HH:mm').format(payment.paidAt),
                  isMonospace: false,
                ),

                const SizedBox(height: AppSpacing.stackLg),

                // ---- Screenshot Area ----------------------------------------
                _buildScreenshotSection(payment.screenshotUrl),
              ],
            ),
          ),
        ),

        // ---- Sticky Action Bar ----------------------------------------------
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, {required bool isMonospace}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.label.copyWith(color: AppColors.inkSecondary),
        ),
        Text(
          value,
          style: isMonospace
              ? AppText.dataLg.copyWith(fontWeight: FontWeight.w700)
              : AppText.bodySm.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildScreenshotSection(String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PAYMENT RECEIPT SCREENSHOT',
          style: AppText.label.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.inkPrimary,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.border),
                  ),
                )
              : const Center(
                  child: Text(
                    'SCREENSHOT PLACEHOLDER',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: SafeArea(
        child: Row(
          children: [
            // Reject Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _rejectPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.signal,
                    side: const BorderSide(color: AppColors.signal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cornerRadius),
                    ),
                  ),
                  child: Text(
                    'REJECT',
                    style: AppText.bodyLg.copyWith(
                      color: AppColors.signal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),

            // Confirm Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inkPrimary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cornerRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : Text(
                          'CONFIRM PAYMENT',
                          style: AppText.bodyLg.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w600,
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
}

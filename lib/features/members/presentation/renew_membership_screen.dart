import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../pricing/data/pricing_repository.dart';
import '../data/members_repository.dart';
import '../domain/membership.dart';
import '../domain/membership_math.dart';
import 'member_detail_controller.dart';
import 'member_list_controller.dart';

class RenewMembershipScreen extends ConsumerStatefulWidget {
  const RenewMembershipScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<RenewMembershipScreen> createState() => _RenewMembershipScreenState();
}

class _RenewMembershipScreenState extends ConsumerState<RenewMembershipScreen> {
  String _planType = 'weight'; // default
  int _durationMonths = 1; // default
  bool _hasInitializedPlan = false;
  double _price = 0.0;
  DateTime? _computedNewDueDate;

  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(memberDetailControllerProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Renew',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: detailState.when(
        data: (data) {
          final membership = data.latestMembership;
          if (!_hasInitializedPlan) {
            _planType = membership?.planType ?? 'weight';
            _hasInitializedPlan = true;
          }

          // Asynchronously resolve price and new due date
          _resolveRenewalDetails(membership?.dueDate);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.containerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Member Info --------------------------------------
                      Text(data.member.name, style: AppText.display),
                      const SizedBox(height: AppSpacing.unit),
                      Text(
                        _buildStatusSubtext(membership),
                        style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
                      ),

                      const SizedBox(height: AppSpacing.stackLg),

                      // ---- Plan Selection ------------------------------------
                      Text(
                        'PLAN',
                        style: AppText.label.copyWith(color: AppColors.inkSecondary),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Row(
                        children: [
                          _buildPlanButton('weight', 'Weight Only'),
                          const SizedBox(width: AppSpacing.gutter),
                          _buildPlanButton('cardio_weight', 'Cardio + Weight'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),

                      // ---- Duration Selection -------------------------------
                      Text(
                        'RENEW FOR',
                        style: AppText.label.copyWith(color: AppColors.inkSecondary),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      _buildDurationGrid(_planType),

                      const SizedBox(height: AppSpacing.stackLg),

                      // ---- Price Display Card -------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL PRICE',
                              style: AppText.label.copyWith(color: AppColors.inkSecondary),
                            ),
                            const SizedBox(height: AppSpacing.unit),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹',
                                  style: AppText.display.copyWith(
                                    fontFamily: 'JetBrainsMono',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                  ),
                                ),
                                Text(
                                  _price.toStringAsFixed(2),
                                  style: AppText.display.copyWith(
                                    fontFamily: 'JetBrainsMono',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 48,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.stackLg),

                      // ---- Calculated Due Date -----------------------------
                      if (_computedNewDueDate != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NEW DUE DATE',
                              style: AppText.label.copyWith(color: AppColors.inkSecondary),
                            ),
                            Text(
                              DateFormat('MMM d, yyyy').format(_computedNewDueDate!),
                              style: AppText.dataLg.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),

                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.stackLg),
                        Text(
                          _error!,
                          style: AppText.bodySm.copyWith(color: AppColors.signal),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ---- Bottom Confirmation Button ------------------------------
              _buildConfirmButton(_planType),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.inkPrimary,
            strokeWidth: 2,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load member info.',
            style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
          ),
        ),
      ),
    );
  }

  void _resolveRenewalDetails(DateTime? currentDueDate) async {
    final computedPrice = await ref.read(pricingRepositoryProvider).getPriceFor(
          planType: _planType,
          durationMonths: _durationMonths,
        );

    final baseDueDate = currentDueDate ?? DateTime.now();
    final newDueDate = MembershipMath.calculateNewDueDate(
      currentDueDate: baseDueDate,
      durationMonths: _durationMonths,
      baseRenewalDate: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _price = computedPrice;
        _computedNewDueDate = newDueDate;
      });
    }
  }

  String _buildStatusSubtext(Membership? membership) {
    if (membership == null) return 'No membership active';
    final plan = membership.planLabel;
    final date = DateFormat('MMM d, yyyy').format(membership.dueDate);
    if (membership.status == MembershipStatus.expired) {
      return '$plan • Expired $date';
    }
    return '$plan • Due $date';
  }

  Widget _buildPlanButton(String type, String label) {
    final isSelected = _planType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _planType = type;
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.inkPrimary : AppColors.surface,
            border: isSelected
                ? Border.all(color: AppColors.inkPrimary, width: 2)
                : Border.all(color: AppColors.border, width: 1),
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.bodySm.copyWith(
              color: isSelected ? AppColors.surface : AppColors.inkPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationGrid(String planType) {
    final durations = [
      {'months': 1, 'label': '1 Month'},
      {'months': 3, 'label': 'Quarterly'},
      {'months': 6, 'label': 'Half-Yearly'},
      {'months': 12, 'label': 'Yearly'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.stackSm,
      crossAxisSpacing: AppSpacing.stackSm,
      childAspectRatio: 3.5,
      children: durations.map((d) {
        final months = d['months'] as int;
        final label = d['label'] as String;
        final isSelected = _durationMonths == months;

        return GestureDetector(
          onTap: () {
            setState(() {
              _durationMonths = months;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: isSelected
                  ? Border.all(color: AppColors.inkPrimary, width: 2)
                  : Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.bodySm.copyWith(
                color: isSelected ? AppColors.inkPrimary : AppColors.inkSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmRenewal(String planType) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(membersRepositoryProvider).renewMembership(
            memberId: widget.memberId,
            planType: planType,
            durationMonths: _durationMonths,
            priceCharged: _price,
          );

      // Refresh listings
      ref.invalidate(memberDetailControllerProvider(widget.memberId));
      ref.invalidate(allMembersProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed: ${e.toString()}";
      });
    }
  }

  Widget _buildConfirmButton(String planType) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _confirmRenewal(planType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inkPrimary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.inkPrimary.withValues(alpha: 0.4),
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
                    'CONFIRM RENEWAL',
                    style: AppText.bodyLg.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../domain/plan_price.dart';
import 'plan_pricing_controller.dart';

/// ──────────────────────────────────────────────
/// Plan Pricing Settings — Screen 10 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: ← "Pricing"
///   Standard Details:
///     "WEIGHT ONLY" Section with input rows for 1 Mo, Quarterly, Half-Year, Yearly
///     Hairline Divider
///     "CARDIO + WEIGHT" Section with input rows for 1 Mo, Quarterly, Half-Year, Yearly
///   Fixed bottom "Save Prices" action button.
/// ──────────────────────────────────────────────
class PlanPricingScreen extends ConsumerStatefulWidget {
  const PlanPricingScreen({super.key});

  @override
  ConsumerState<PlanPricingScreen> createState() => _PlanPricingScreenState();
}

class _PlanPricingScreenState extends ConsumerState<PlanPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Local controllers map to preserve typed values
  final Map<String, TextEditingController> _controllers = {};
  
  bool _initialized = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers(List<PlanPrice> prices) {
    if (_initialized) return;
    for (final price in prices) {
      _controllers[price.id] = TextEditingController(text: price.price.toStringAsFixed(0));
    }
    _initialized = true;
  }

  Future<void> _savePrices(List<PlanPrice> originalPrices) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final updatedPrices = originalPrices.map((p) {
      final text = _controllers[p.id]!.text;
      final newPrice = double.tryParse(text) ?? p.price;
      return PlanPrice(
        id: p.id,
        planType: p.planType,
        durationMonths: p.durationMonths,
        price: newPrice,
      );
    }).toList();

    try {
      await ref.read(planPricingControllerProvider.notifier).savePrices(updatedPrices);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prices updated successfully.'),
            backgroundColor: AppColors.inkPrimary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to save prices. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingState = ref.watch(planPricingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pricing',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: pricingState.when(
        data: (prices) {
          _initControllers(prices);
          
          final weightPrices = prices.where((p) => p.planType == 'weight').toList();
          final cardioPrices = prices.where((p) => p.planType == 'cardio_weight').toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.containerPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ---- Weight Only Section ----------------------------
                        _buildSectionHeader('Weight Only'),
                        const SizedBox(height: AppSpacing.stackSm),
                        _buildPriceCard(weightPrices),

                        const SizedBox(height: AppSpacing.stackLg),
                        const Divider(color: AppColors.border, thickness: 1),
                        const SizedBox(height: AppSpacing.stackLg),

                        // ---- Cardio + Weight Section ------------------------
                        _buildSectionHeader('Cardio + Weight'),
                        const SizedBox(height: AppSpacing.stackSm),
                        _buildPriceCard(cardioPrices),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.stackLg),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.signal),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Bottom Action Button ------------------------------------
              _buildSaveButton(prices),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load pricing configurations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextButton(
                onPressed: () => ref.read(planPricingControllerProvider.notifier).refresh(),
                child: Text('Retry', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.inkPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.inkSecondary,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildPriceCard(List<PlanPrice> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return _buildInputRow(item, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildInputRow(PlanPrice item, bool isLast) {
    final label = switch (item.durationMonths) {
      1  => '1 Month',
      3  => 'Quarterly',
      6  => 'Half-Yearly',
      12 => 'Yearly',
      _  => '${item.durationMonths} Months',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '₹',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.inkPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    controller: _controllers[item.id],
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                    ),
                    textAlign: TextAlign.right,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal <= 0) return 'Invalid';
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(List<PlanPrice> originalPrices) {
    final isSaving = ref.watch(planPricingControllerProvider).isLoading;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : () => _savePrices(originalPrices),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.inkPrimary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.inkPrimary.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : Text(
                    'SAVE PRICES',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

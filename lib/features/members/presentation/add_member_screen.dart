import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../pricing/data/pricing_repository.dart';
import '../data/members_repository.dart';
import 'member_list_controller.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  String _planType = 'weight'; // default
  int _durationMonths = 1; // default
  double _price = 45.0; // default (Basic 1 Month)

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _updatePrice();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePrice() async {
    final computedPrice = await ref.read(pricingRepositoryProvider).getPriceFor(
          planType: _planType,
          durationMonths: _durationMonths,
        );
    if (mounted) {
      setState(() {
        _price = computedPrice;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: appTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.inkPrimary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.inkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(membersRepositoryProvider).createMember(
            name: _nameController.text.trim(),
            phoneNo: _phoneController.text.trim(),
            planType: _planType,
            durationMonths: _durationMonths,
            priceCharged: _price,
            startDate: _startDate,
          );

      // Refresh list
      ref.invalidate(memberListControllerProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Couldn't save member. Check connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Member',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Name & Phone fields container ----------------------
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border.symmetric(
                          horizontal: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            placeholder: 'Enter full name',
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Phone number is required'
                                : null,
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildDatePickerRow(),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ---- Plan Selection ------------------------------------
                    _buildSectionHeader('Plan'),
                    const SizedBox(height: AppSpacing.stackSm),
                    Row(
                      children: [
                        _buildPlanButton('weight', 'Weight Only'),
                        const SizedBox(width: AppSpacing.gutter),
                        _buildPlanButton('cardio_weight', 'Cardio + Weight'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ---- Duration Selection ---------------------------------
                    _buildSectionHeader('Duration'),
                    const SizedBox(height: AppSpacing.stackSm),
                    _buildDurationGrid(),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ---- Error Display --------------------------------------
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: AppText.bodySm.copyWith(color: AppColors.signal),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                    ],

                    // ---- Price Display --------------------------------------
                    _buildPriceDisplay(),
                  ],
                ),
              ),
            ),
          ),

          // ---- Bottom Save Action -------------------------------------------
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppText.label.copyWith(color: AppColors.inkSecondary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.label.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.unit),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppText.bodyLg,
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppText.bodyLg.copyWith(color: AppColors.inkSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow() {
    return GestureDetector(
      onTap: () => _selectStartDate(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'START DATE',
                  style: AppText.label.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  DateFormat('yyyy-MM-dd').format(_startDate),
                  style: AppText.dataLg,
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: AppColors.inkSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanButton(String type, String label) {
    final isSelected = _planType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _planType = type;
          });
          _updatePrice();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.inkPrimary : AppColors.surface,
            border: Border.all(color: AppColors.inkPrimary),
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

  Widget _buildDurationGrid() {
    final durations = [
      {'months': 1, 'label': '1 Month'},
      {'months': 3, 'label': 'Quarterly'},
      {'months': 6, 'label': 'Half-Yearly'},
      {'months': 12, 'label': 'Yearly'},
    ];

    return Wrap(
      spacing: AppSpacing.unit * 2,
      runSpacing: AppSpacing.unit * 2,
      children: durations.map((d) {
        final months = d['months'] as int;
        final label = d['label'] as String;
        final isSelected = _durationMonths == months;

        return GestureDetector(
          onTap: () {
            setState(() {
              _durationMonths = months;
            });
            _updatePrice();
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - AppSpacing.containerPadding * 2 - AppSpacing.unit * 6) / 2,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.inkPrimary : AppColors.surface,
              border: Border.all(color: AppColors.border),
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
        );
      }).toList(),
    );
  }

  Widget _buildPriceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Divider(color: AppColors.border, thickness: 1),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'TOTAL DUE',
          style: AppText.label.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          '₹${_price.toStringAsFixed(2)}',
          style: AppText.display.copyWith(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
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
            onPressed: _isLoading ? null : _saveMember,
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
                    'SAVE MEMBER',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../pricing/data/pricing_repository.dart';
import '../data/members_repository.dart';
import '../domain/membership_math.dart';
import 'member_list_controller.dart';
import 'member_detail_controller.dart';


class EditMemberScreen extends ConsumerStatefulWidget {
  const EditMemberScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _priceOverrideController;

  bool _initialized = false;
  String? _membershipId;

  DateTime _startDate = DateTime.now();
  DateTime? _customDueDate;
  DateTime? _customPaymentDate;

  String _planType = 'weight';
  int _durationMonths = 1;
  double _price = 45.0;

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _phoneController.dispose();
      _photoUrlController.dispose();
      _priceOverrideController.dispose();
    }
    super.dispose();
  }

  void _initFields(MemberDetailData data) {
    if (_initialized) return;

    final member = data.member;
    final membership = data.latestMembership;

    _nameController = TextEditingController(text: member.name);
    _phoneController = TextEditingController(text: member.phoneNo);
    _photoUrlController = TextEditingController(text: member.photoUrl ?? '');

    if (membership != null) {
      _membershipId = membership.id;
      _startDate = membership.startDate;
      _customDueDate = membership.dueDate;
      _customPaymentDate = membership.paymentDate;
      _planType = membership.planType;
      _durationMonths = membership.durationMonths;
      _price = membership.priceCharged;
    }

    _priceOverrideController = TextEditingController(text: _price.toStringAsFixed(2));
    _initialized = true;
  }

  Future<void> _updatePrice() async {
    final computedPrice = await ref.read(pricingRepositoryProvider).getPriceFor(
          planType: _planType,
          durationMonths: _durationMonths,
        );
    if (mounted) {
      setState(() {
        _price = computedPrice;
        _priceOverrideController.text = _price.toStringAsFixed(2);
      });
    }
  }

  Widget _datePickerBuilder(BuildContext context, Widget? child) {
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
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _datePickerBuilder,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectCustomPaymentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customPaymentDate ?? _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _datePickerBuilder,
    );
    if (picked != null) {
      setState(() => _customPaymentDate = picked);
    }
  }

  Future<void> _selectCustomDueDate(BuildContext context) async {
    final calculated = MembershipMath.calculateNewDueDate(
      currentDueDate: _startDate,
      durationMonths: _durationMonths,
      baseRenewalDate: _startDate,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDueDate ?? calculated,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _datePickerBuilder,
    );
    if (picked != null) {
      setState(() => _customDueDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final priceToSave = double.tryParse(_priceOverrideController.text.trim()) ?? _price;

      await ref.read(membersRepositoryProvider).updateMember(
            id: widget.memberId,
            name: _nameController.text.trim(),
            phoneNo: _phoneController.text.trim(),
            photoUrl: _photoUrlController.text.trim(),
            membershipId: _membershipId,
            planType: _planType,
            durationMonths: _durationMonths,
            priceCharged: priceToSave,
            startDate: _startDate,
            dueDate: _customDueDate,
            paymentDate: _customPaymentDate,
          );

      ref.invalidate(memberDetailControllerProvider(widget.memberId));
      ref.invalidate(allMembersProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint("Error saving member: $e");
      setState(() {
        _isLoading = false;
        _error = "Couldn't save member: $e";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(memberDetailControllerProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Member',
          style: AppText.headline.copyWith(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: detailState.when(
        data: (data) {
          _initFields(data);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(cornerRadius),
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
                            readOnly: true,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Phone number is required'
                                : null,
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildTextField(
                            controller: _photoUrlController,
                            label: 'Photo URL (Optional)',
                            placeholder: 'Enter image link',
                            keyboardType: TextInputType.url,
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildDateSelectorRow(
                            label: 'START DATE',
                            date: _startDate,
                            onTap: () => _selectStartDate(context),
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildDateSelectorRow(
                            label: 'PAYMENT DATE',
                            date: _customPaymentDate ?? _startDate,
                            onTap: () => _selectCustomPaymentDate(context),
                          ),
                          const Divider(height: 1, thickness: 1, color: AppColors.border),
                          _buildDueDatePickerRow(),
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
    bool readOnly = false,
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
            style: AppText.bodyLg.copyWith(color: readOnly ? AppColors.inkSecondary : AppColors.inkPrimary),
            validator: validator,
            readOnly: readOnly,
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

  Widget _buildDateSelectorRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                  label,
                  style: AppText.label.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.unit),
                Row(
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: AppText.dataLg,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: AppSpacing.unit),
                      Text(
                        subtitle,
                        style: AppText.label.copyWith(
                          color: AppColors.inkPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Icon(Icons.edit_calendar_outlined, color: AppColors.inkPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDatePickerRow() {
    final calculated = MembershipMath.calculateNewDueDate(
      currentDueDate: _startDate,
      durationMonths: _durationMonths,
      baseRenewalDate: _startDate,
    );
    final isCustom = _customDueDate != null;
    final displayDate = _customDueDate ?? calculated;

    return _buildDateSelectorRow(
      label: 'DUE DATE',
      date: displayDate,
      subtitle: isCustom ? '(Custom)' : '(Auto)',
      onTap: () => _selectCustomDueDate(context),
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
          'PRICE PAID (₹)',
          style: AppText.label.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.unit),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: _priceOverrideController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: AppText.display.copyWith(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
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
            onPressed: _isLoading ? null : _saveChanges,
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
                    'SAVE CHANGES',
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

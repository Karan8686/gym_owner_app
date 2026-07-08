import re

with open("lib/features/members/presentation/add_member_screen.dart", "r") as f:
    add_member_content = f.read()

# Replace AddMemberScreen with EditMemberScreen
content = add_member_content.replace("AddMemberScreen", "EditMemberScreen")

# Add memberId parameter
content = content.replace(
    "const EditMemberScreen({super.key});",
    "const EditMemberScreen({super.key, required this.memberId});\n\n  final String memberId;"
)

# Imports adjustments
content = content.replace("import 'member_list_controller.dart';", "import 'member_list_controller.dart';\nimport 'member_detail_controller.dart';\nimport '../domain/membership.dart';")

# State variables adjustments
content = re.sub(
    r"class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {.*?\n  bool _isLoading = false;",
    """class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
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

  bool _isLoading = false;""",
    content,
    flags=re.DOTALL
)

# Init and dispose adjustments
content = re.sub(
    r"  @override\n  void initState\(\) \{\n    super.initState\(\);\n    _updatePrice\(\);\n  \}\n\n  @override\n  void dispose\(\) \{\n    _nameController.dispose\(\);\n    _phoneController.dispose\(\);\n    _photoUrlController.dispose\(\);\n    _priceOverrideController.dispose\(\);\n    super.dispose\(\);\n  \}",
    """  @override
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
  }""",
    content
)

# Replace _saveMember with _saveChanges
content = re.sub(
    r"Future<void> _saveMember\(\) async \{.*?\n  \}",
    """Future<void> _saveChanges() async {
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

  Future<void> _removeMember() async {
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

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(membersRepositoryProvider).deleteMember(widget.memberId);
      ref.invalidate(memberListControllerProvider);

      if (mounted) {
        context.go('/members');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to remove member. Check your connection.";
      });
    }
  }""",
    content,
    flags=re.DOTALL
)

# App bar title and layout modifications
content = content.replace("'Add Member'", "'Edit Member'")
content = content.replace("_saveMember", "_saveChanges")
content = content.replace("'SAVE MEMBER'", "'SAVE CHANGES'")

# Replace build body
content = re.sub(
    r"  @override\n  Widget build\(BuildContext context\) \{\n    return Scaffold\(\n      backgroundColor: AppColors.background,\n      appBar: AppBar\(.*?\),\n      body: Column\(\n        children: \[\n          Expanded\(\n            child: SingleChildScrollView\(",
    """  @override
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
            children: [
              Expanded(
                child: SingleChildScrollView(""",
    content,
    flags=re.DOTALL
)

# Close the detailState.when at the end of build
content = re.sub(
    r"          // ---- Bottom Save Action -------------------------------------------\n          _buildSaveButton\(\),\n        \],\n      \),\n    \);\n  \}",
    """          // ---- Bottom Save Action -------------------------------------------
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
  }""",
    content
)

# Update TextField signature to accept readOnly
content = content.replace(
    "TextInputType keyboardType = TextInputType.text,\n    String? Function(String?)? validator,\n  }) {",
    "TextInputType keyboardType = TextInputType.text,\n    String? Function(String?)? validator,\n    bool readOnly = false,\n  }) {"
)
content = content.replace(
    "style: AppText.bodyLg,\n            validator: validator,",
    "style: AppText.bodyLg.copyWith(color: readOnly ? AppColors.inkSecondary : AppColors.inkPrimary),\n            validator: validator,\n            readOnly: readOnly,"
)

# Set phone number field to readOnly
content = content.replace(
    "_buildTextField(\n                            controller: _phoneController,\n                            label: 'Phone Number',\n                            placeholder: 'Enter phone number',\n                            keyboardType: TextInputType.phone,\n                            validator: (val) => val == null || val.trim().isEmpty\n                                ? 'Phone number is required'\n                                : null,\n                          ),",
    "_buildTextField(\n                            controller: _phoneController,\n                            label: 'Phone Number',\n                            placeholder: 'Enter phone number',\n                            keyboardType: TextInputType.phone,\n                            readOnly: true,\n                            validator: (val) => val == null || val.trim().isEmpty\n                                ? 'Phone number is required'\n                                : null,\n                          ),"
)

# Insert remove member button before price display
content = content.replace(
    "// ---- Price Display --------------------------------------\n                    _buildPriceDisplay(),",
    """_buildRemoveButton(),
                    const SizedBox(height: AppSpacing.stackLg),
                    // ---- Price Display --------------------------------------
                    _buildPriceDisplay(),"""
)

# Insert remove button helper function
content = content.replace(
    "  Widget _buildSaveButton() {",
    """  Widget _buildRemoveButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _removeMember,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.signal,
        side: const BorderSide(color: AppColors.signal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        'Remove Member',
        style: AppText.bodyLg.copyWith(
          color: AppColors.signal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {"""
)

with open("lib/features/members/presentation/edit_member_screen.dart", "w") as f:
    f.write(content)


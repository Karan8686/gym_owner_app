import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../data/members_repository.dart';
import 'member_detail_controller.dart';
import 'member_list_controller.dart';

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

  bool _initialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _phoneController.dispose();
    }
    super.dispose();
  }

  void _initFields(String name, String phone) {
    if (_initialized) return;
    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _initialized = true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(membersRepositoryProvider).updateMember(
            id: widget.memberId,
            name: _nameController.text.trim(),
            phoneNo: _phoneController.text.trim(),
          );

      // Refresh detail and list
      ref.invalidate(memberDetailControllerProvider(widget.memberId));
      ref.invalidate(memberListControllerProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Couldn't update member details. Check your connection.";
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

      // Refresh list
      ref.invalidate(memberListControllerProvider);

      if (mounted) {
        // Go back to member list (not detail since detail was deleted)
        context.go('/members');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to remove member. Check your connection.";
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
          style: AppText.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: detailState.when(
        data: (data) {
          _initFields(data.member.name, data.member.phoneNo);

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
                        // ---- Member Details Inputs --------------------------
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
                                placeholder: 'Enter name',
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
                                    ? 'Phone is required'
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.stackLg),

                        // ---- Destructive Action -----------------------------
                        _buildRemoveButton(),

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
              ),

              // ---- Bottom Action Bar ----------------------------------------
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

  Widget _buildRemoveButton() {
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

import re

with open("lib/features/members/presentation/renew_membership_screen.dart", "r") as f:
    content = f.read()

# Add _planType state variable
content = re.sub(
    r"class _RenewMembershipScreenState extends ConsumerState<RenewMembershipScreen> \{\n  int _durationMonths = 1; // default",
    "class _RenewMembershipScreenState extends ConsumerState<RenewMembershipScreen> {\n  String _planType = 'weight'; // default\n  int _durationMonths = 1; // default\n  bool _hasInitializedPlan = false;",
    content
)

# Update _resolveRenewalDetails to use _planType
content = re.sub(
    r"void _resolveRenewalDetails\(DateTime\? currentDueDate\) async \{\n    final computedPrice = await ref.read\(pricingRepositoryProvider\)\.getPriceFor\(\n          planType: 'weight', // fallback/default lookup",
    "void _resolveRenewalDetails(DateTime? currentDueDate) async {\n    final computedPrice = await ref.read(pricingRepositoryProvider).getPriceFor(\n          planType: _planType,",
    content
)

# Modify the build method to initialize _planType once
content = re.sub(
    r"          final planType = membership\?\.planType \?\? 'weight';\n\n          // Asynchronously resolve price and new due date\n          _resolveRenewalDetails\(membership\?\.dueDate\);",
    """          if (!_hasInitializedPlan) {
            _planType = membership?.planType ?? 'weight';
            _hasInitializedPlan = true;
          }

          // Asynchronously resolve price and new due date
          _resolveRenewalDetails(membership?.dueDate);""",
    content
)

# Add plan type selector UI
content = re.sub(
    r"                      // ---- Duration Selection -------------------------------",
    """                      // ---- Plan Selection ------------------------------------
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

                      // ---- Duration Selection -------------------------------""",
    content
)

# Add _buildPlanButton method
content = re.sub(
    r"  Widget _buildDurationGrid\(String planType\) \{",
    """  Widget _buildPlanButton(String type, String label) {
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

  Widget _buildDurationGrid(String planType) {""",
    content
)

# Replace 'planType' with '_planType' for method arguments in build
content = content.replace("_buildDurationGrid(planType)", "_buildDurationGrid(_planType)")
content = content.replace("_buildConfirmButton(planType)", "_buildConfirmButton(_planType)")

# Change error handling in _confirmRenewal to print exception
content = re.sub(
    r"    \} catch \(e\) \{\n      setState\(\(\) \{\n        _isLoading = false;\n        _error = 'Failed to confirm renewal\. Check your connection\.';\n      \}\);\n    \}",
    """    } catch (e) {
      print("Error confirming renewal: $e");
      setState(() {
        _isLoading = false;
        _error = "Failed: ${e.toString()}";
      });
    }""",
    content
)

with open("lib/features/members/presentation/renew_membership_screen.dart", "w") as f:
    f.write(content)

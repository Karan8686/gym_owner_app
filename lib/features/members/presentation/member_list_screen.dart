import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/router/app_router.dart';
import '../data/members_repository.dart';
import 'member_list_controller.dart';

/// ──────────────────────────────────────────────
/// Member List & Search — Screen 3 from GOAL.md.
///
/// Layout (per Stitch mockup):
///   Top bar: "FitTrack Owner"
///   Search field: "Search name or phone"
///   Filter tabs: ALL | ACTIVE | EXPIRING | EXPIRED
///   Member rows: name + phone, days remaining (monospace)
///   FAB: + Add Member
///   Bottom nav
/// ──────────────────────────────────────────────
class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(memberSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(memberListControllerProvider);
    final currentFilter = ref.watch(memberFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildSearchField(),
            _buildFilterTabs(currentFilter),
            Expanded(
              child: membersState.when(
                data: (members) => _buildMemberList(context, ref, members),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.inkPrimary,
                    strokeWidth: 2,
                  ),
                ),
                error: (error, _) => _buildError(ref),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // --------------------------------------------------------------------------
  // Top bar
  // --------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.inkPrimary, size: 24),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Text(
              'FitTrack Owner',
              style: AppText.headline.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.inkPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Search field
  // --------------------------------------------------------------------------
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.stackMd,
        AppSpacing.gutter,
        AppSpacing.stackSm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppText.bodySm,
        decoration: InputDecoration(
          hintText: 'Search name or phone',
          hintStyle: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackSm,
            vertical: AppSpacing.stackSm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(
              color: AppColors.inkPrimary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Filter tabs: ALL | ACTIVE | EXPIRING | EXPIRED
  // --------------------------------------------------------------------------
  Widget _buildFilterTabs(MemberStatusFilter current) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.stackSm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          children: MemberStatusFilter.values.map((filter) {
            final isActive = filter == current;
            return _buildTabItem(
              label: filter.name.toUpperCase(),
              isActive: isActive,
              onTap: () {
                ref.read(memberFilterProvider.notifier).state = filter;
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.stackSm,
          left: AppSpacing.stackSm,
          right: AppSpacing.stackSm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.inkPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            color: isActive ? AppColors.inkPrimary : AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Member list
  // --------------------------------------------------------------------------
  Widget _buildMemberList(
    BuildContext context,
    WidgetRef ref,
    List<MemberWithMembership> members,
  ) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Text(
            'No members found.',
            style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.inkPrimary,
      onRefresh: () =>
          ref.read(memberListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.stackMd,
        ).copyWith(bottom: 180),
        itemCount: members.length,
        itemBuilder: (context, index) {
          return _buildMemberRow(context, members[index]);
        },
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, MemberWithMembership item) {
    final days = item.daysRemaining;
    // Color: expired/≤7 days → signal red, otherwise inkPrimary
    final daysColor = (days != null && days <= 7)
        ? AppColors.signal
        : AppColors.inkPrimary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/members/${item.member.id}'),
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.inkPrimary.withValues(alpha: 0.1),
                backgroundImage: (item.member.photoUrl != null && item.member.photoUrl!.isNotEmpty)
                    ? NetworkImage(item.member.photoUrl!)
                    : null,
                child: (item.member.photoUrl == null || item.member.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.inkPrimary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.gutter),
              // Middle: name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.member.name, style: AppText.bodyLg),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      item.member.phoneNo,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: days remaining (monospace)
              if (days != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      days.toString(),
                      style: AppText.display.copyWith(
                        color: daysColor,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'DAYS',
                      style: AppText.label.copyWith(
                        color: AppColors.inkSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Error state
  // --------------------------------------------------------------------------
  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load members. Check your connection and try again.",
              style: AppText.bodySm.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(
              onPressed: () =>
                  ref.read(memberListControllerProvider.notifier).refresh(),
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

  // --------------------------------------------------------------------------
  // FAB
  // --------------------------------------------------------------------------
  Widget _buildFab(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 110),
      child: ElevatedButton(
        onPressed: () => context.push(AppRoutes.addMember),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.inkPrimary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
            vertical: AppSpacing.stackSm,
          ),
        ),
        child: Text(
          '+ Add Member',
          style: AppText.bodySm.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }


}

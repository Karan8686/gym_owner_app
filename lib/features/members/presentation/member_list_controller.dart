import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/members_repository.dart';
import '../domain/membership.dart';

// ---------------------------------------------------------------------------
// Current filter state
// ---------------------------------------------------------------------------
final memberFilterProvider =
    StateProvider<MemberStatusFilter>((ref) => MemberStatusFilter.all);

// ---------------------------------------------------------------------------
// Search query
// ---------------------------------------------------------------------------
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Member list controller
// ---------------------------------------------------------------------------
final memberListControllerProvider = AsyncNotifierProvider<
    MemberListController, List<MemberWithMembership>>(
  MemberListController.new,
);

final allMembersProvider = FutureProvider<List<MemberWithMembership>>((ref) async {
  return ref.read(membersRepositoryProvider).getMembers();
});

class MemberListController extends AsyncNotifier<List<MemberWithMembership>> {
  @override
  FutureOr<List<MemberWithMembership>> build() async {
    final allMembers = await ref.watch(allMembersProvider.future);
    
    final filter = ref.watch(memberFilterProvider);
    final query = ref.watch(memberSearchQueryProvider).toLowerCase();
    final now = DateTime.now();

    return allMembers.where((m) {
      // 1. Search match
      if (query.isNotEmpty) {
        if (!m.member.name.toLowerCase().contains(query) &&
            !m.member.phoneNo.contains(query)) {
          return false;
        }
      }

      // 2. Filter match
      if (filter != MemberStatusFilter.all) {
        if (m.latestMembership == null) return false;
        final status = m.latestMembership!.status;

        if (filter == MemberStatusFilter.active && status != MembershipStatus.active) {
          return false;
        }
        if (filter == MemberStatusFilter.expired && status != MembershipStatus.expired) {
          return false;
        }
        if (filter == MemberStatusFilter.expiring) {
          if (status != MembershipStatus.active) return false;
          final daysLeft = m.latestMembership!.dueDate.difference(now).inDays;
          if (daysLeft > 7) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidate(allMembersProvider);
  }
}

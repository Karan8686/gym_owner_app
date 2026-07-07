import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/members_repository.dart';

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

class MemberListController extends AsyncNotifier<List<MemberWithMembership>> {
  late final MembersRepository _repo;

  @override
  FutureOr<List<MemberWithMembership>> build() async {
    _repo = ref.read(membersRepositoryProvider);

    // Re-fetch when filter or search changes.
    final filter = ref.watch(memberFilterProvider);
    final query = ref.watch(memberSearchQueryProvider);

    return _repo.getMembers(filter: filter, searchQuery: query);
  }

  /// Pull-to-refresh.
  Future<void> refresh() async {
    final filter = ref.read(memberFilterProvider);
    final query = ref.read(memberSearchQueryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getMembers(filter: filter, searchQuery: query),
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payments_repository.dart';

final pendingPaymentsControllerProvider = AsyncNotifierProvider<
    PendingPaymentsController, List<PendingPaymentItem>>(
  PendingPaymentsController.new,
);

class PendingPaymentsController
    extends AsyncNotifier<List<PendingPaymentItem>> {
  late final PaymentsRepository _repo;

  @override
  FutureOr<List<PendingPaymentItem>> build() async {
    _repo = ref.read(paymentsRepositoryProvider);
    return _repo.getPendingPayments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getPendingPayments());
  }

  Future<void> confirmPayment({
    required String paymentId,
    required String membershipId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.confirmPayment(
        paymentId: paymentId,
        membershipId: membershipId,
      );
      return _repo.getPendingPayments();
    });
  }

  Future<void> rejectPayment({required String paymentId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.rejectPayment(paymentId: paymentId);
      return _repo.getPendingPayments();
    });
  }
}

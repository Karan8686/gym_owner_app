import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException;

import '../data/auth_repository.dart';
import '../domain/owner.dart';

// ---------------------------------------------------------------------------
// Auth state — exposed as an AsyncNotifier so the UI gets loading/error/data.
// ---------------------------------------------------------------------------

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Owner?>(AuthController.new);

class AuthController extends AsyncNotifier<Owner?> {
  late final AuthRepository _repo;

  @override
  FutureOr<Owner?> build() {
    _repo = ref.read(authRepositoryProvider);

    // Listen for Supabase auth changes (token refresh, sign-out from another
    // device, etc.) and update state reactively.
    final sub = _repo.authStateChanges.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedOut) {
        state = const AsyncData(null);
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        final user = _repo.currentUser;
        if (user != null) {
          state = AsyncData(Owner.fromSupabaseUser(user));
        }
      }
    });

    // Cancel the subscription when the provider is disposed.
    ref.onDispose(() => sub.cancel());

    // Seed with the current session (if one exists from a previous run).
    final user = _repo.currentUser;
    return user != null ? Owner.fromSupabaseUser(user) : null;
  }

  // ---- Commands -----------------------------------------------------------

  /// Email + PIN login. Returns `null` on success, or an error message string.
  Future<String?> signIn({
    required String email,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _repo.signInWithPassword(
        email: email,
        password: pin,
      );
      final user = response.user;
      if (user != null) {
        state = AsyncData(Owner.fromSupabaseUser(user));
        return null;
      } else {
        state = const AsyncData(null);
        return 'Login failed. Please check your credentials.';
      }
    } on AuthException catch (e) {
      state = const AsyncData(null);
      return e.message;
    } catch (e) {
      state = const AsyncData(null);
      return 'Something went wrong. Check your connection and try again.';
    }
  }

  /// Sign out — clears session and resets state.
  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }
}

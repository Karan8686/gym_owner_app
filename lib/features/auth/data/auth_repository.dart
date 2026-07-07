import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_owner_app/core/config/supabase_config.dart';

// ---------------------------------------------------------------------------
// Auth Repository — the only place Supabase Auth is touched.
// Screens and controllers never call Supabase.instance.client directly.
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  AuthRepository();

  // ---- Queries --------------------------------------------------------------

  /// Current Supabase session (null if signed out).
  Session? get currentSession => supabase.auth.currentSession;

  /// Current Supabase user (null if signed out).
  User? get currentUser => supabase.auth.currentUser;

  /// Reactive stream of auth state changes.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // ---- Commands -------------------------------------------------------------

  /// Sign in with email + password (the 4-digit PIN is the password).
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out and clear the local session.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

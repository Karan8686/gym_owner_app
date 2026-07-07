import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Minimal domain model for the gym owner.
///
/// Maps from a Supabase `User` — no extra fields for v1 since there's
/// only a single admin user.
class Owner {
  const Owner({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String email;
  final DateTime createdAt;

  /// Create an [Owner] from the Supabase auth [User] object.
  factory Owner.fromSupabaseUser(User user) {
    return Owner(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.parse(user.createdAt),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize the Supabase client.
///
/// The project URL and anon key are read from environment variables
/// passed via `--dart-define` at build time:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
/// ```
///
/// Never commit secrets — keep them in your CI env or a local
/// `.env` file that's in `.gitignore`.
/// Global error message if Supabase initialization fails.
String? supabaseInitError;

Future<void> initSupabase() async {
  const supabaseUrl = 'https://ohfmvhazzihvwperpjlk.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oZm12aGF6emlodndwZXJwamxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0MDkxNjEsImV4cCI6MjA5ODk4NTE2MX0.a62tg8WzQBPsMlO8CRpIUuYgXJ0-vIVnL6RB-OxM8cY';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    supabaseInitError = 'Failed to initialize Supabase:\n$e';
  }
}

/// Convenience accessor — use through a repository, not directly in widgets.
SupabaseClient get supabase {
  if (supabaseInitError != null) {
    throw StateError(supabaseInitError!);
  }
  return Supabase.instance.client;
}

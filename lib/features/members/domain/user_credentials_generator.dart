class UserCredentialsGenerator {
  /// Fixed prefix prepended to the PIN to meet Supabase's 6-character
  /// minimum password requirement. The member-facing UI still shows only
  /// the 4-digit PIN — this prefix is added transparently at signup and login.
  static const passwordPrefix = 'ft';

  /// Generates the User ID (email format) as `firstname@lastname`.
  /// If only one name is supplied, falls back to `firstname@firstname`.
  static String generateEmail(String fullName) {
    final cleanName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleanName.toLowerCase().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) {
      return 'user@gym.com';
    }
    final firstName = parts[0];
    final lastName = parts.length > 1 ? parts.sublist(1).join('') : firstName;
    return '$firstName@$lastName';
  }

  /// Generates the password as `ft` + last 4 digits of phone number.
  /// Supabase Auth requires at least 6 characters, so the 2-char prefix
  /// ensures compliance. If the phone number has fewer than 4 digits,
  /// uses whatever is available (or defaults to `0000`).
  static String generatePassword(String phoneNo) {
    // Extract all numeric digits from phone number
    final cleanPhone = phoneNo.replaceAll(RegExp(r'\D'), '');
    final phonePart = cleanPhone.length >= 4
        ? cleanPhone.substring(cleanPhone.length - 4)
        : (cleanPhone.isNotEmpty ? cleanPhone : '0000');

    return '$passwordPrefix$phonePart';
  }
}


import 'package:json_annotation/json_annotation.dart';

part 'member.g.dart';

/// A gym member.
///
/// Maps 1:1 to the `members` Supabase table.
/// Column names stay snake_case end-to-end per SKILL.md — only the Dart
/// field name is camelCase, bridged via `@JsonKey`.
@JsonSerializable()
class Member {
  const Member({
    required this.id,
    required this.srNo,
    required this.name,
    required this.phoneNo,
    this.photoUrl,
    this.authUserId,
    required this.createdAt,
  });

  final String id;

  @JsonKey(name: 'sr_no')
  final int srNo;

  final String name;

  @JsonKey(name: 'phone_no')
  final String phoneNo;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  @JsonKey(name: 'auth_user_id')
  final String? authUserId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}

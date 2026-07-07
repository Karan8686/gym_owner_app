// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
  id: json['id'] as String,
  srNo: (json['sr_no'] as num).toInt(),
  name: json['name'] as String,
  phoneNo: json['phone_no'] as String,
  photoUrl: json['photo_url'] as String?,
  authUserId: json['auth_user_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'id': instance.id,
  'sr_no': instance.srNo,
  'name': instance.name,
  'phone_no': instance.phoneNo,
  'photo_url': instance.photoUrl,
  'auth_user_id': instance.authUserId,
  'created_at': instance.createdAt.toIso8601String(),
};

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.locale,
    this.phone,
    this.avatarPath,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    locale: json['locale'] as String? ?? 'bn',
    phone: json['phone'] as String?,
    avatarPath: json['avatar_path'] as String?,
  );

  final String id;
  final String fullName;

  /// 'bn' or 'en'.
  final String locale;
  final String? phone;
  final String? avatarPath;
}

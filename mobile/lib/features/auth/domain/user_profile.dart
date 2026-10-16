class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.organization,
    required this.groups,
    required this.projectIds,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    name: (json['name'] as String?) ?? '',
    organization: (json['organization'] as String?) ?? '',
    groups: List<String>.from(json['groups'] as List? ?? const []),
    projectIds: List<String>.from(json['project_ids'] as List? ?? const []),
  );

  final String id;
  final String email;
  final String name;
  final String organization;
  final List<String> groups;
  final List<String> projectIds;

  bool get isAdmin => groups.contains('admin');
  String get displayName => name.isNotEmpty ? name : email;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'organization': organization,
    'groups': groups,
    'project_ids': projectIds,
  };
}
